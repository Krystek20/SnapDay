import Foundation
import StoreKit

actor StoreKitPaymentService {
  private let productIDs: Set<String>
  private let snapshotStore: EntitlementSnapshotStore
  private let storeKit: StoreKitClient
  private let now: @Sendable () -> Date
  private var continuations: [UUID: AsyncStream<PremiumEntitlement>.Continuation] = [:]
  private var transactionListener: Task<Void, Never>?
  private var lastEntitlement: PremiumEntitlement?

  init(
    productIDs: Set<String> = Set(SnapDayPlusProduct.allCases.map(\.rawValue)),
    snapshotStore: EntitlementSnapshotStore = .live,
    storeKit: StoreKitClient = .live,
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.productIDs = productIDs
    self.snapshotStore = snapshotStore
    self.storeKit = storeKit
    self.now = now
  }

  deinit {
    transactionListener?.cancel()
  }

  func products() async throws -> [SubscriptionProduct] {
    try await storeKit.products(productIDs).map {
      SubscriptionProduct(
        id: $0.id,
        displayName: $0.displayName,
        displayPrice: $0.displayPrice,
        subscriptionPeriod: $0.subscriptionPeriod,
        isEligibleForIntroductoryOffer: $0.isEligibleForIntroductoryOffer
      )
    }
  }

  func currentEntitlement() async -> PremiumEntitlement {
    do {
      return try await refreshEntitlement()
    } catch {
      let entitlement = snapshotStore.entitlementForOfflineUse(at: now())
      publish(entitlement)
      return entitlement
    }
  }

  func updates() -> AsyncStream<PremiumEntitlement> {
    let id = UUID()
    startTransactionListenerIfNeeded()

    return AsyncStream { continuation in
      continuations[id] = continuation
      continuation.onTermination = { [weak self] _ in
        Task { await self?.removeContinuation(id) }
      }

      let initial = lastEntitlement ?? snapshotStore.entitlementForOfflineUse(at: now())
      lastEntitlement = initial
      continuation.yield(initial)
      Task { _ = await self.currentEntitlement() }
    }
  }

  func purchase(productID: String) async throws -> PurchaseOutcome {
    guard productIDs.contains(productID) else {
      throw PaymentError.productUnavailable
    }

    switch try await storeKit.purchase(productID) {
    case .success(let transaction):
      guard transaction.productID == productID else {
        throw PaymentError.unexpectedTransaction
      }
      let entitlement = transaction.entitlement(at: now())
      guard entitlement.hasAccess else {
        throw PaymentError.entitlementUnavailable
      }
      try persistAndPublish(entitlement)
      await transaction.finish()
      return .purchased(entitlement)
    case .pending:
      return .pending
    case .cancelled:
      return .cancelled
    }
  }

  func restore() async throws -> RestoreOutcome {
    try await storeKit.sync()
    return try await refreshEntitlement().restoreOutcome
  }

  private func refreshEntitlement(
    including updatedTransaction: StoreTransaction? = nil
  ) async throws -> PremiumEntitlement {
    let entitlement = try await resolvedEntitlement(including: updatedTransaction)
    try persistAndPublish(entitlement)
    return entitlement
  }

  private func resolvedEntitlement(
    including updatedTransaction: StoreTransaction? = nil
  ) async throws -> PremiumEntitlement {
    var transactions = try await storeKit.currentEntitlements(productIDs)
    if let updatedTransaction {
      transactions.append(updatedTransaction)
    }
    let transactionEntitlement = PremiumEntitlement.resolve(
      transactions: transactions,
      at: now()
    )

    do {
      let statusEntitlement = PremiumEntitlement.resolve(
        candidates: try await storeKit.subscriptionStatuses(productIDs)
      )
      return statusEntitlement.hasAccess ? statusEntitlement : transactionEntitlement ?? statusEntitlement
    } catch {
      return transactionEntitlement ?? .free
    }
  }

  private func startTransactionListenerIfNeeded() {
    guard transactionListener == nil else { return }
    transactionListener = Task { [weak self, storeKit, productIDs] in
      for await transaction in storeKit.transactionUpdates(productIDs) {
        guard let self else { return }
        await self.handle(transaction)
      }
    }
  }

  private func handle(_ transaction: StoreTransaction) async {
    do {
      _ = try await refreshEntitlement(including: transaction)
      await transaction.finish()
    } catch {
      // Leave the transaction unfinished so StoreKit can deliver it again.
    }
  }

  private func persistAndPublish(_ entitlement: PremiumEntitlement) throws {
    try snapshotStore.save(
      EntitlementSnapshot(entitlement: entitlement, updatedAt: now())
    )
    publish(entitlement)
  }

  private func publish(_ entitlement: PremiumEntitlement) {
    guard lastEntitlement != entitlement else { return }
    lastEntitlement = entitlement
    continuations.values.forEach { $0.yield(entitlement) }
  }

  private func removeContinuation(_ id: UUID) {
    continuations[id] = nil
  }
}

struct EntitlementCandidate: Equatable, Sendable {
  let productID: String
  let state: Product.SubscriptionInfo.RenewalState
  let expirationDate: Date?
  let revocationDate: Date?
  let isIntroductoryOffer: Bool
}

extension PremiumEntitlement {
  static func resolve(
    transactions: [StoreTransaction],
    at date: Date
  ) -> PremiumEntitlement? {
    transactions
      .map { $0.entitlement(at: date) }
      .max(by: { $0.selectionPriority < $1.selectionPriority })
  }

  static func resolve(candidates: [EntitlementCandidate]) -> PremiumEntitlement {
    guard let candidate = candidates.max(by: { $0.isLowerPriority(than: $1) }) else {
      return .free
    }

    switch candidate.state {
    case .subscribed:
      return candidate.isIntroductoryOffer
        ? .trial(expirationDate: candidate.expirationDate)
        : .subscribed(expirationDate: candidate.expirationDate)
    case .inGracePeriod:
      return .gracePeriod(expirationDate: candidate.expirationDate)
    case .inBillingRetryPeriod:
      return .billingRetry(expirationDate: candidate.expirationDate)
    case .expired:
      return .expired(expirationDate: candidate.expirationDate)
    case .revoked:
      return .revoked(revocationDate: candidate.revocationDate)
    default:
      return .unknown
    }
  }
}

private extension EntitlementCandidate {
  func isLowerPriority(than other: Self) -> Bool {
    if statePriority != other.statePriority {
      return statePriority < other.statePriority
    }
    if expirationDate != other.expirationDate {
      return (expirationDate ?? .distantPast) < (other.expirationDate ?? .distantPast)
    }
    return productID < other.productID
  }

  var statePriority: Int {
    switch state {
    case .subscribed: 6
    case .inGracePeriod: 5
    case .inBillingRetryPeriod: 4
    case .expired: 3
    case .revoked: 2
    default: 1
    }
  }
}

private extension PremiumEntitlement {
  var selectionPriority: (Int, Date) {
    switch self {
    case .trial(let expirationDate), .subscribed(let expirationDate):
      (6, expirationDate ?? .distantFuture)
    case .gracePeriod(let expirationDate):
      (5, expirationDate ?? .distantFuture)
    case .billingRetry(let expirationDate):
      (4, expirationDate ?? .distantPast)
    case .expired(let expirationDate):
      (3, expirationDate ?? .distantPast)
    case .revoked(let revocationDate):
      (2, revocationDate ?? .distantPast)
    case .unknown:
      (1, .distantPast)
    case .free:
      (0, .distantPast)
    }
  }
}

extension PaymentClient {
  static func live(service: StoreKitPaymentService = StoreKitPaymentService()) -> PaymentClient {
    PaymentClient(
      products: { try await service.products() },
      currentEntitlement: { await service.currentEntitlement() },
      entitlementUpdates: { service.updatesSync() },
      purchase: { try await service.purchase(productID: $0) },
      restore: { try await service.restore() }
    )
  }
}

private extension StoreKitPaymentService {
  nonisolated func updatesSync() -> AsyncStream<PremiumEntitlement> {
    AsyncStream { continuation in
      let task = Task {
        for await entitlement in await updates() {
          continuation.yield(entitlement)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
