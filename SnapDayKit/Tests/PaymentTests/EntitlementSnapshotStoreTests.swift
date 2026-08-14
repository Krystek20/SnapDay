import Foundation
@testable import Payment
import Testing

struct EntitlementSnapshotStoreTests {
  @Test
  func savesAndLoadsCurrentSnapshot() throws {
    let suiteName = "EntitlementSnapshotStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = EntitlementSnapshotStore(userDefaults: userDefaults)
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)
    let snapshot = EntitlementSnapshot(
      entitlement: .subscribed(expirationDate: expirationDate),
      updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    try store.save(snapshot)

    #expect(store.load() == snapshot)
  }

  @Test
  func ignoresSnapshotFromUnsupportedSchema() throws {
    let suiteName = "EntitlementSnapshotStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = EntitlementSnapshotStore(userDefaults: userDefaults)
    let snapshot = EntitlementSnapshot(
      schemaVersion: EntitlementSnapshot.currentSchemaVersion + 1,
      entitlement: .subscribed(expirationDate: nil),
      updatedAt: .now
    )

    try store.save(snapshot)

    #expect(store.load() == nil)
  }

  @Test
  func recentlyVerifiedSubscriberKeepsAccessWhileOffline() throws {
    let suiteName = "EntitlementSnapshotStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = EntitlementSnapshotStore(userDefaults: userDefaults)
    let verificationDate = Date(timeIntervalSince1970: 1_700_000_000)
    let entitlement = PremiumEntitlement.subscribed(expirationDate: verificationDate)
    try store.save(
      EntitlementSnapshot(entitlement: entitlement, updatedAt: verificationDate)
    )

    let offlineDate = verificationDate.addingTimeInterval(
      EntitlementSnapshotStore.offlineAccessInterval / 2
    )

    #expect(store.entitlementForOfflineUse(at: offlineDate) == entitlement)
  }

  @Test
  func staleActiveSnapshotBecomesUnknownWhileOffline() throws {
    let suiteName = "EntitlementSnapshotStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = EntitlementSnapshotStore(userDefaults: userDefaults)
    let verificationDate = Date(timeIntervalSince1970: 1_700_000_000)
    try store.save(
      EntitlementSnapshot(
        entitlement: .subscribed(expirationDate: nil),
        updatedAt: verificationDate
      )
    )

    let offlineDate = verificationDate.addingTimeInterval(
      EntitlementSnapshotStore.offlineAccessInterval + 1
    )

    #expect(store.entitlementForOfflineUse(at: offlineDate) == .unknown)
  }

  @Test
  func savePropagatesEncodingFailure() throws {
    let suiteName = "EntitlementSnapshotStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = EntitlementSnapshotStore(
      userDefaults: userDefaults,
      encoder: { _ in throw TestError.encodingFailed }
    )

    #expect(throws: TestError.encodingFailed) {
      try store.save(
        EntitlementSnapshot(entitlement: .free, updatedAt: .now)
      )
    }
  }
}

private enum TestError: Error {
  case encodingFailed
}
