public struct PlanProgress: Equatable, Hashable {

  // MARK: - Properties

  public let completedPlannedActivityCount: Int
  public let totalPlannedActivityCount: Int

  public var fractionComplete: Double {
    guard totalPlannedActivityCount > 0 else { return 0 }
    return Double(completedPlannedActivityCount) / Double(totalPlannedActivityCount)
  }

  public var percentComplete: Int {
    Int((fractionComplete * 100).rounded())
  }

  // MARK: - Initialization

  public init(
    occurrences: [PlanOccurrence],
    dayActivities: [DayActivity]
  ) {
    let completedDayActivityIDs = Set(
      dayActivities.lazy.filter(\.isDone).map(\.id)
    )
    completedPlannedActivityCount = occurrences.lazy.filter {
      $0.dayActivityID.map(completedDayActivityIDs.contains) ?? false
    }.count
    totalPlannedActivityCount = occurrences.count
  }
}
