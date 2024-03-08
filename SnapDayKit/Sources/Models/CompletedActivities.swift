import Foundation

public struct CompletedActivities {
  
  public let doneCount: Int
  public let totalCount: Int
  public let percent: Double

  public init(doneCount: Int, totalCount: Int, percent: Double) {
    self.doneCount = doneCount
    self.totalCount = totalCount
    self.percent = percent
  }
}
