import Foundation
import Testing
@testable import Payment

struct PremiumAccessTests {

  @Test
  func accessReflectsFreshSharedEntitlementSnapshot() throws {
    let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
    let store = EntitlementSnapshotStore(userDefaults: defaults)
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    try store.save(
      EntitlementSnapshot(
        entitlement: .subscribed(expirationDate: nil),
        updatedAt: now
      )
    )

    #expect(PremiumAccess.hasAccess(at: now, snapshotStore: store))
  }

  @Test
  func staleSnapshotDoesNotGrantAccess() throws {
    let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
    let store = EntitlementSnapshotStore(userDefaults: defaults)
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    try store.save(
      EntitlementSnapshot(
        entitlement: .subscribed(expirationDate: nil),
        updatedAt: now.addingTimeInterval(-EntitlementSnapshotStore.offlineAccessInterval - 1)
      )
    )

    #expect(!PremiumAccess.hasAccess(at: now, snapshotStore: store))
  }
}
