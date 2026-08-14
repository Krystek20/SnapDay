import Foundation
import StoreKit

struct StoreKitClient: Sendable {
  var products: @Sendable (_ productIDs: Set<String>) async throws -> [StoreProduct]
  var currentEntitlements: @Sendable (_ productIDs: Set<String>) async throws -> [StoreTransaction]
  var subscriptionStatuses: @Sendable (_ productIDs: Set<String>) async throws -> [EntitlementCandidate]
  var transactionUpdates: @Sendable (_ productIDs: Set<String>) -> AsyncStream<StoreTransaction>
  var purchase: @Sendable (_ productID: String) async throws -> StorePurchaseResult
  var sync: @Sendable () async throws -> Void
}

struct StoreProduct: Equatable, Sendable {
  let id: String
  let displayName: String
  let displayPrice: String
  let subscriptionPeriod: SubscriptionPeriod
  let isEligibleForIntroductoryOffer: Bool
  let price: Decimal
}

struct StoreTransaction: Sendable {
  let productID: String
  let expirationDate: Date?
  let revocationDate: Date?
  let isIntroductoryOffer: Bool
  let finish: @Sendable () async -> Void

  func entitlement(at date: Date) -> PremiumEntitlement {
    if let revocationDate {
      return .revoked(revocationDate: revocationDate)
    }
    if let expirationDate, expirationDate <= date {
      return .expired(expirationDate: expirationDate)
    }
    return isIntroductoryOffer
      ? .trial(expirationDate: expirationDate)
      : .subscribed(expirationDate: expirationDate)
  }
}

enum StorePurchaseResult: Sendable {
  case success(StoreTransaction)
  case pending
  case cancelled
}

extension StoreKitClient {
  static let live = StoreKitClient(
    products: { productIDs in
      let products = try await Product.products(for: productIDs)
      var storeProducts: [StoreProduct] = []
      for product in products {
        guard let subscription = product.subscription else { continue }
        storeProducts.append(
          StoreProduct(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            subscriptionPeriod: SubscriptionPeriod(
              value: subscription.subscriptionPeriod.value,
              unit: subscription.subscriptionPeriod.unit.paymentUnit
            ),
            isEligibleForIntroductoryOffer: await subscription.isEligibleForIntroOffer,
            price: product.price
          )
        )
      }
      return storeProducts.sorted {
        $0.price == $1.price ? $0.id < $1.id : $0.price < $1.price
      }
    },
    currentEntitlements: { productIDs in
      var transactions: [StoreTransaction] = []
      for await result in Transaction.currentEntitlements {
        switch result {
        case .verified(let transaction):
          guard productIDs.contains(transaction.productID) else { continue }
          transactions.append(StoreTransaction(transaction))
        case .unverified(let transaction, _):
          guard productIDs.contains(transaction.productID) else { continue }
          throw PaymentError.unverifiedTransaction
        }
      }
      return transactions
    },
    subscriptionStatuses: { productIDs in
      let products = try await Product.products(for: productIDs)
      var candidates: [EntitlementCandidate] = []

      for product in products {
        guard let subscription = product.subscription else { continue }
        for status in try await subscription.status {
          let transaction = try status.transaction.verifiedValue
          guard productIDs.contains(transaction.productID) else { continue }
          guard !transaction.isUpgraded else { continue }
          candidates.append(
            EntitlementCandidate(
              productID: transaction.productID,
              state: status.state,
              expirationDate: transaction.expirationDate,
              revocationDate: transaction.revocationDate,
              isIntroductoryOffer: transaction.offerType == .introductory
            )
          )
        }
      }
      return candidates
    },
    transactionUpdates: { productIDs in
      AsyncStream { continuation in
        let task = Task {
          for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            continuation.yield(StoreTransaction(transaction))
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    },
    purchase: { productID in
      guard let product = try await Product.products(for: [productID]).first else {
        throw PaymentError.productUnavailable
      }

      switch try await product.purchase() {
      case .success(let verification):
        return .success(StoreTransaction(try verification.verifiedValue))
      case .pending:
        return .pending
      case .userCancelled:
        return .cancelled
      @unknown default:
        throw PaymentError.unknownPurchaseResult
      }
    },
    sync: {
      try await AppStore.sync()
    }
  )
}

private extension StoreTransaction {
  init(_ transaction: Transaction) {
    self.init(
      productID: transaction.productID,
      expirationDate: transaction.expirationDate,
      revocationDate: transaction.revocationDate,
      isIntroductoryOffer: transaction.offerType == .introductory,
      finish: { await transaction.finish() }
    )
  }
}

private extension VerificationResult {
  var verifiedValue: SignedType {
    get throws {
      switch self {
      case .verified(let value):
        return value
      case .unverified:
        throw PaymentError.unverifiedTransaction
      }
    }
  }
}

extension Product.SubscriptionPeriod.Unit {
  fileprivate var paymentUnit: SubscriptionPeriod.Unit {
    switch self {
    case .day: .day
    case .week: .week
    case .month: .month
    case .year: .year
    @unknown default: .month
    }
  }
}
