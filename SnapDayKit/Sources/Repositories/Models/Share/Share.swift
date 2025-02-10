import CloudKit

public struct Share: Equatable {
  public let ckShare: CKShare
  public let container: CKContainer

  func fill(with title: String, thumbnailImageData: Data?) {
    ckShare[CKShare.SystemFieldKey.title] = title
    ckShare[CKShare.SystemFieldKey.thumbnailImageData] = thumbnailImageData
  }

  public static func == (lhs: Share, rhs: Share) -> Bool {
      lhs.ckShare.recordID == rhs.ckShare.recordID && lhs.container.containerIdentifier == rhs.container.containerIdentifier
  }
}
