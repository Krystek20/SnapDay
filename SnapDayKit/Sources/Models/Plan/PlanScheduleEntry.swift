import Foundation

public struct PlanScheduleEntry: Equatable, Hashable, Identifiable {

  // MARK: - Properties

  public let id: UUID
  public var weekday: PlanWeekday
  public var activityID: Activity.ID
  public var position: Int

  // MARK: - Initialization

  public init(
    id: UUID,
    weekday: PlanWeekday,
    activityID: Activity.ID,
    position: Int
  ) {
    self.id = id
    self.weekday = weekday
    self.activityID = activityID
    self.position = position
  }
}
