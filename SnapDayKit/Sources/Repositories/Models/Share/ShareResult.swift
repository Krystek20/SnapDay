import CloudKit
import Models

public struct ShareResult: Equatable {
  public let ckShare: CKShare
  public let container: CKContainer

  public static func == (lhs: ShareResult, rhs: ShareResult) -> Bool {
      lhs.ckShare.recordID == rhs.ckShare.recordID && lhs.container.containerIdentifier == rhs.container.containerIdentifier
  }
}
