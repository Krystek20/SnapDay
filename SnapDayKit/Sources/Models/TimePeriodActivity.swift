import Foundation

public struct TimePeriodActivity: Identifiable, Equatable {

  public enum HeaderItemType: Equatable {
    case icon(Icon?)
    case color(RGBColor)
  }

  public var id: String
  public let name: String
  public let type: HeaderItemType
  public let totalCount: Int
  public let doneCount: Int
  public let duration: Int
  public let showProgress: Bool
  public let isImportant: Bool

  public init(
    id: String,
    name: String,
    type: HeaderItemType,
    totalCount: Int,
    doneCount: Int,
    duration: Int,
    showProgress: Bool,
    isImportant: Bool
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.totalCount = totalCount
    self.doneCount = doneCount
    self.duration = duration
    self.showProgress = showProgress
    self.isImportant = isImportant
  }
}

extension TimePeriodActivity {
  public var completedValue: Double {
    guard totalCount != .zero else { return .zero }
    return min(Double(doneCount) / Double(totalCount), 1.0)
  }

  public var percent: Int {
    Int(completedValue * 100)
  }
}
