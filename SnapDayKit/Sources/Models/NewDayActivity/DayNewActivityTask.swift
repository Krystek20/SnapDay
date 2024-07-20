import Foundation

public struct DayNewActivityTask: Equatable {

  public static let empty = DayNewActivityTask(
    activityId: nil,
    name: "",
    isFormVisible: false
  )

  public var activityId: UUID?
  public var name: String
  public var isFormVisible: Bool

  public init(
    activityId: UUID?,
    name: String,
    isFormVisible: Bool
  ) {
    self.activityId = activityId
    self.name = name
    self.isFormVisible = isFormVisible
  }
}
