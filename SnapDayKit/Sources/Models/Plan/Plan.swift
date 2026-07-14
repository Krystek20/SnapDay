import Foundation

public struct Plan: Equatable, Hashable, Identifiable {

  // MARK: - Properties

  public let id: UUID
  public var name: String
  public var startDate: Date
  public var endDate: Date
  public var duration: PlanDuration
  public var isArchived: Bool
  public var schedule: [PlanScheduleEntry]

  // MARK: - Initialization

  public init(
    id: UUID,
    name: String,
    startDate: Date,
    endDate: Date,
    duration: PlanDuration,
    isArchived: Bool = false,
    schedule: [PlanScheduleEntry]
  ) {
    self.id = id
    self.name = name
    self.startDate = startDate
    self.endDate = endDate
    self.duration = duration
    self.isArchived = isArchived
    self.schedule = schedule
  }
}

public extension Plan {
  func status(
    on date: Date,
    calendar: Calendar = .autoupdatingCurrent
  ) -> PlanStatus {
    guard !isArchived else { return .archived }
    return calendar.startOfDay(for: date) > calendar.startOfDay(for: endDate)
      ? .finished
      : .active
  }

  func scheduledOccurrences(
    from lowerBound: Date? = nil,
    through upperBound: Date? = nil,
    calendar: Calendar = .autoupdatingCurrent
  ) -> [PlanOccurrence] {
    let planStart = calendar.startOfDay(for: startDate)
    let planEnd = calendar.startOfDay(for: endDate)
    let firstDate = max(planStart, lowerBound.map(calendar.startOfDay(for:)) ?? planStart)
    let lastDate = min(planEnd, upperBound.map(calendar.startOfDay(for:)) ?? planEnd)
    guard firstDate <= lastDate else { return [] }

    let entriesByWeekday = Dictionary(grouping: schedule, by: \.weekday)
    var occurrences: [PlanOccurrence] = []
    var date = firstDate

    while date <= lastDate {
      if let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date)) {
        var activityIDs = Set<Activity.ID>()
        let entries = entriesByWeekday[weekday, default: []].sorted { $0.position < $1.position }

        for entry in entries where activityIDs.insert(entry.activityID).inserted {
          occurrences.append(
            PlanOccurrence(
              planID: self.id,
              activityID: entry.activityID,
              date: date
            )
          )
        }
      }

      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
      date = nextDate
    }

    return occurrences
  }

  func progress(
    from occurrences: [PlanOccurrence],
    dayActivities: [DayActivity]
  ) -> PlanProgress {
    PlanProgress(
      occurrences: occurrences.filter { $0.planID == id },
      dayActivities: dayActivities
    )
  }
}
