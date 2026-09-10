import Dependencies
import Foundation

public struct PaymentClient: Sendable {
  public var products: @Sendable () async throws -> [SubscriptionProduct]
  public var currentEntitlement: @Sendable () async -> PremiumEntitlement
  public var entitlementUpdates: @Sendable () -> AsyncStream<PremiumEntitlement>
  public var purchase: @Sendable (_ productID: String) async throws -> PurchaseOutcome
  public var restore: @Sendable () async throws -> RestoreOutcome

  public init(
    products: @escaping @Sendable () async throws -> [SubscriptionProduct],
    currentEntitlement: @escaping @Sendable () async -> PremiumEntitlement,
    entitlementUpdates: @escaping @Sendable () -> AsyncStream<PremiumEntitlement>,
    purchase: @escaping @Sendable (_ productID: String) async throws -> PurchaseOutcome,
    restore: @escaping @Sendable () async throws -> RestoreOutcome
  ) {
    self.products = products
    self.currentEntitlement = currentEntitlement
    self.entitlementUpdates = entitlementUpdates
    self.purchase = purchase
    self.restore = restore
  }
}

extension DependencyValues {
  public var paymentClient: PaymentClient {
    get { self[PaymentClient.self] }
    set { self[PaymentClient.self] = newValue }
  }
}

extension PaymentClient: DependencyKey {
  public static let liveValue = PaymentClient.live()

  public static let testValue = PaymentClient(
    products: { [] },
    currentEntitlement: { .free },
    entitlementUpdates: { AsyncStream { $0.finish() } },
    purchase: { _ in .cancelled },
    restore: { .noActiveEntitlement }
  )
}
