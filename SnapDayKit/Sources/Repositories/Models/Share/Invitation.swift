import CloudKit

public struct Invitation {
  let cloudKitShareMetadata: CKShare.Metadata

  public init(cloudKitShareMetadata: CKShare.Metadata) {
    self.cloudKitShareMetadata = cloudKitShareMetadata
  }
}
