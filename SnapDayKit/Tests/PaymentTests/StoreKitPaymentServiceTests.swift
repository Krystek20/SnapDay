import Foundation
@testable import Payment
import Testing

struct StoreKitPaymentServiceTests {
  @Test
  func activeEntitlementDoesNotDependOnProductMetadata() async throws {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: try snapshotStore(),
      storeKit: StoreKitClient(
        products: { _ in throw TestError.unavailable },
        currentEntitlements: { _ in
          [StoreTransaction.stub(expirationDate: expirationDate)]
        },
        subscriptionStatuses: { _ in throw TestError.unavailable },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .cancelled },
        sync: {}
      ),
      now: { Date(timeIntervalSince1970: 1_700_000_000) }
    )

    let entitlement = await service.currentEntitlement()

    #expect(entitlement == .subscribed(expirationDate: expirationDate))
  }

  @Test
  func purchasePersistsAccessBeforeFinishingTransaction() async throws {
    let store = try snapshotStore()
    let recorder = FinishRecorder()
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)
    let transaction = StoreTransaction.stub(
      expirationDate: expirationDate,
      finish: {
        await recorder.record(store.load()?.entitlement)
      }
    )
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: store,
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in [] },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .success(transaction) },
        sync: {}
      ),
      now: { Date(timeIntervalSince1970: 1_700_000_000) }
    )

    let outcome = try await service.purchase(productID: SnapDayPlusProduct.monthly.rawValue)

    let entitlement = PremiumEntitlement.subscribed(expirationDate: expirationDate)
    #expect(outcome == .purchased(entitlement))
    #expect(await recorder.entitlement == entitlement)
  }

  @Test
  func purchaseDoesNotFinishWithoutDeliverableAccess() async throws {
    let recorder = FinishRecorder()
    let transaction = StoreTransaction.stub(
      expirationDate: Date(timeIntervalSince1970: 1_600_000_000),
      finish: { await recorder.record(.free) }
    )
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: try snapshotStore(),
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in [] },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .success(transaction) },
        sync: {}
      ),
      now: { Date(timeIntervalSince1970: 1_700_000_000) }
    )

    await #expect(throws: PaymentError.entitlementUnavailable) {
      try await service.purchase(productID: SnapDayPlusProduct.monthly.rawValue)
    }
    #expect(await recorder.entitlement == nil)
  }

  @Test
  func purchaseDoesNotFinishWhenSnapshotCannotBeSaved() async throws {
    let recorder = FinishRecorder()
    let transaction = StoreTransaction.stub(
      expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
      finish: { await recorder.record(.free) }
    )
    let store = try failingSnapshotStore()
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: store,
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in [] },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .success(transaction) },
        sync: {}
      ),
      now: { Date(timeIntervalSince1970: 1_700_000_000) }
    )

    await #expect(throws: TestError.encodingFailed) {
      try await service.purchase(productID: SnapDayPlusProduct.monthly.rawValue)
    }
    #expect(await recorder.entitlement == nil)
  }

  @Test
  func candidateSelectionUsesLatestExpirationForEqualStates() {
    let earlierDate = Date(timeIntervalSince1970: 1_700_000_000)
    let laterDate = Date(timeIntervalSince1970: 1_800_000_000)

    let entitlement = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .subscribed,
          expirationDate: earlierDate,
          revocationDate: nil,
          isIntroductoryOffer: true
        ),
        EntitlementCandidate(
          productID: SnapDayPlusProduct.annual.rawValue,
          state: .subscribed,
          expirationDate: laterDate,
          revocationDate: nil,
          isIntroductoryOffer: false
        )
      ]
    )

    #expect(entitlement == .subscribed(expirationDate: laterDate))
  }

  @Test
  func restoreReportsNoActiveEntitlementAfterSync() async throws {
    let recorder = SyncRecorder()
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: try snapshotStore(),
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in [] },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .cancelled },
        sync: { await recorder.record() }
      )
    )

    let outcome = try await service.restore()

    #expect(outcome == .noActiveEntitlement)
    #expect(await recorder.wasCalled)
  }

  @Test
  func restoreDoesNotReportCachedAccessWhenVerificationFails() async throws {
    let store = try snapshotStore()
    try store.save(
      EntitlementSnapshot(
        entitlement: .subscribed(expirationDate: nil),
        updatedAt: .now
      )
    )
    let service = StoreKitPaymentService(
      productIDs: [SnapDayPlusProduct.monthly.rawValue],
      snapshotStore: store,
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in throw TestError.unavailable },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .cancelled },
        sync: {}
      )
    )

    await #expect(throws: TestError.unavailable) {
      try await service.restore()
    }
  }

  @Test
  func purchaseRejectsTransactionForDifferentProduct() async throws {
    let transaction = StoreTransaction.stub(
      productID: SnapDayPlusProduct.annual.rawValue,
      expirationDate: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let service = StoreKitPaymentService(
      productIDs: Set(SnapDayPlusProduct.allCases.map(\.rawValue)),
      snapshotStore: try snapshotStore(),
      storeKit: StoreKitClient(
        products: { _ in [] },
        currentEntitlements: { _ in [] },
        subscriptionStatuses: { _ in [] },
        transactionUpdates: { _ in .finished },
        purchase: { _ in .success(transaction) },
        sync: {}
      )
    )

    await #expect(throws: PaymentError.unexpectedTransaction) {
      try await service.purchase(productID: SnapDayPlusProduct.monthly.rawValue)
    }
  }
}

private enum TestError: Error {
  case encodingFailed
  case unavailable
}

private actor FinishRecorder {
  private(set) var entitlement: PremiumEntitlement?

  func record(_ entitlement: PremiumEntitlement?) {
    self.entitlement = entitlement
  }
}

private actor SyncRecorder {
  private(set) var wasCalled = false

  func record() {
    wasCalled = true
  }
}

private extension StoreTransaction {
  static func stub(
    productID: String = SnapDayPlusProduct.monthly.rawValue,
    expirationDate: Date?,
    finish: @escaping @Sendable () async -> Void = {}
  ) -> StoreTransaction {
    StoreTransaction(
      productID: productID,
      expirationDate: expirationDate,
      revocationDate: nil,
      isIntroductoryOffer: false,
      finish: finish
    )
  }
}

private extension AsyncStream where Element == StoreTransaction {
  static var finished: AsyncStream {
    AsyncStream { $0.finish() }
  }
}

private func snapshotStore() throws -> EntitlementSnapshotStore {
  let suiteName = "StoreKitPaymentServiceTests.\(UUID().uuidString)"
  let userDefaults = try #require(UserDefaults(suiteName: suiteName))
  userDefaults.removePersistentDomain(forName: suiteName)
  return EntitlementSnapshotStore(userDefaults: userDefaults)
}

private func failingSnapshotStore() throws -> EntitlementSnapshotStore {
  let suiteName = "StoreKitPaymentServiceTests.\(UUID().uuidString)"
  let userDefaults = try #require(UserDefaults(suiteName: suiteName))
  userDefaults.removePersistentDomain(forName: suiteName)
  return EntitlementSnapshotStore(
    userDefaults: userDefaults,
    encoder: { _ in throw TestError.encodingFailed }
  )
}
