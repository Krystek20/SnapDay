import Foundation
import OSLog

public struct EntitlementSnapshot: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public let schemaVersion: Int
  public let entitlement: PremiumEntitlement
  public let updatedAt: Date

  public init(
    schemaVersion: Int = EntitlementSnapshot.currentSchemaVersion,
    entitlement: PremiumEntitlement,
    updatedAt: Date
  ) {
    self.schemaVersion = schemaVersion
    self.entitlement = entitlement
    self.updatedAt = updatedAt
  }
}

// UserDefaults supports concurrent reads and writes, despite lacking Sendable conformance.
public struct EntitlementSnapshotStore: @unchecked Sendable {
  public static let appGroupIdentifier = "group.com.mobilove.snapday"
  public static let offlineAccessInterval: TimeInterval = 24 * 60 * 60

  private static let snapshotKey = "premium.entitlement.snapshot"
  private let userDefaults: UserDefaults
  private let encoder: @Sendable (EntitlementSnapshot) throws -> Data
  private let decoder: @Sendable (Data) throws -> EntitlementSnapshot

  public init(
    userDefaults: UserDefaults,
    encoder: @escaping @Sendable (EntitlementSnapshot) throws -> Data = { try JSONEncoder().encode($0) },
    decoder: @escaping @Sendable (Data) throws -> EntitlementSnapshot = { try JSONDecoder().decode(EntitlementSnapshot.self, from: $0) }
  ) {
    self.userDefaults = userDefaults
    self.encoder = encoder
    self.decoder = decoder
  }

  public static var live: EntitlementSnapshotStore {
    guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
      Logger.payment.error("Unable to open entitlement App Group; using standard defaults")
      return EntitlementSnapshotStore(userDefaults: .standard)
    }
    return EntitlementSnapshotStore(userDefaults: userDefaults)
  }

  public func load() -> EntitlementSnapshot? {
    guard
      let data = userDefaults.data(forKey: Self.snapshotKey),
      let snapshot = try? decoder(data),
      snapshot.schemaVersion == EntitlementSnapshot.currentSchemaVersion
    else { return nil }
    return snapshot
  }

  public func entitlementForOfflineUse(at date: Date) -> PremiumEntitlement {
    guard let snapshot = load() else { return .unknown }
    guard snapshot.entitlement.hasAccess else { return snapshot.entitlement }

    let age = max(0, date.timeIntervalSince(snapshot.updatedAt))
    return age <= Self.offlineAccessInterval ? snapshot.entitlement : .unknown
  }

  public func save(_ snapshot: EntitlementSnapshot) throws {
    let data = try encoder(snapshot)
    userDefaults.set(data, forKey: Self.snapshotKey)
  }
}

private extension Logger {
  static let payment = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.mobilove.snapday",
    category: "Payment"
  )
}
