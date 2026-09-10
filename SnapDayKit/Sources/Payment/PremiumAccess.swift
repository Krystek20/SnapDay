import Foundation

public enum PremiumAccess {
  public static func hasAccess(
    at date: Date = .now,
    snapshotStore: EntitlementSnapshotStore = .live
  ) -> Bool {
    snapshotStore.entitlementForOfflineUse(at: date).hasAccess
  }
}
