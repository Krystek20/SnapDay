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
  public var isSkipped: Bool

  public var id: ID {
    ID(planID: planID, activityID: activityID, date: date)
  }

  // MARK: - Initialization

  public init(
    planID: Plan.ID,
    activityID: Activity.ID,
    date: Date,
    dayActivityID: DayActivity.ID? = nil,
    isSkipped: Bool = false
  ) {
    self.planID = planID
    self.activityID = activityID
    self.date = date
    self.dayActivityID = dayActivityID
    self.isSkipped = isSkipped
  }
}

public extension Sequence where Element == PlanOccurrence {
  func deduplicatedByID() -> [PlanOccurrence] {
    var occurrences: [PlanOccurrence] = []
    var indicesByID: [PlanOccurrence.ID: Int] = [:]

    for occurrence in self {
      if let index = indicesByID[occurrence.id] {
        if !occurrences[index].isSkipped,
           occurrence.isSkipped ||
           (occurrences[index].dayActivityID == nil && occurrence.dayActivityID != nil) {
          occurrences[index] = occurrence
        }
      } else {
        indicesByID[occurrence.id] = occurrences.endIndex
        occurrences.append(occurrence)
      }
    }

    return occurrences
  }
}
