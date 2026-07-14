import Foundation

public struct PlanOccurrence: Equatable, Hashable, Identifiable {

  public struct ID: Equatable, Hashable {
    public let planID: Plan.ID
    public let activityID: Activity.ID
    public let date: Date

    public init(planID: Plan.ID, activityID: Activity.ID, date: Date) {
      self.planID = planID
      self.activityID = activityID
      self.date = date
    }
  }

  // MARK: - Properties

  public let planID: Plan.ID
  public let activityID: Activity.ID
  public let date: Date
  public var dayActivityID: DayActivity.ID?

  public var id: ID {
    ID(planID: planID, activityID: activityID, date: date)
  }

  // MARK: - Initialization

  public init(
    planID: Plan.ID,
    activityID: Activity.ID,
    date: Date,
    dayActivityID: DayActivity.ID? = nil
  ) {
    self.planID = planID
    self.activityID = activityID
    self.date = date
    self.dayActivityID = dayActivityID
  }
}
