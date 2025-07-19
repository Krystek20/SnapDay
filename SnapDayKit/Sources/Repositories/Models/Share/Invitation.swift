import CloudKit

public struct Invitation {
  let identifier: UUID = UUID()
  let cloudKitShareMetadata: CKShare.Metadata

  public init(cloudKitShareMetadata: CKShare.Metadata) {
    self.cloudKitShareMetadata = cloudKitShareMetadata
  }
}
