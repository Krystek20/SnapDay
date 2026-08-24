import Foundation
import Models
import Utilities

struct PlanDetailsContent: Equatable {

  struct ActivityItem: Equatable, Identifiable {
    let id: Activity.ID
    let name: String
    let isDone: Bool
    let isSkipped: Bool
  }

  struct ScheduledDay: Equatable, Identifiable {
    let id: PlanWeekday
    let title: String
    let state: DayState?
    let activities: [ActivityItem]
  }

  enum DayState: Equatable {
    case done
    case partial
    case skipped
    case missed
    case today
    case upcoming

    var title: String.LocalizationValue {
      switch self {
      case .done: "Done"
      case .partial: "Partly done"
      case .skipped: "Skipped"
      case .missed: "Missed"
      case .today: "Today"
      case .upcoming: "Upcoming"
      }
    }
  }

  struct ActivityBreakdown: Equatable, Identifiable {
    let activity: ActivityItem
    let completedCount: Int
    let plannedCount: Int

    var id: Activity.ID { activity.id }
  }

  let plan: Plan
  let activities: [Activity]
  let occurrences: [PlanOccurrence]
  let dayActivities: [DayActivity]
  let referenceDate: Date
  let calendar: Calendar

  var status: PlanStatus {
    plan.status(on: referenceDate, calendar: calendar)
  }

  var progress: PlanProgress {
    plan.progress(from: occurrences, dayActivities: dayActivities)
  }

  var todayActivities: [ActivityItem] {
    activityItems(on: referenceDate)
  }

  var completedTodayCount: Int {
    todayActivities.filter(\.isDone).count
  }

  var scheduledDays: [ScheduledDay] {
    let datesByWeekday = currentWeekDates
    return PlanWeekday.ordered(using: calendar).compactMap { weekday -> ScheduledDay? in
      let entries = plan.schedule
        .filter { $0.weekday == weekday }
        .sorted { $0.position < $1.position }
      guard !entries.isEmpty else { return nil }

      let date = datesByWeekday[weekday]
      if status == .active,
         let date,
         calendar.startOfDay(for: date) > calendar.startOfDay(for: plan.endDate) {
        return nil
      }
      let items = date.map { activityItems(on: $0) } ?? entries.compactMap(activityItem(for:))
      return ScheduledDay(
        id: weekday,
        title: weekday.title(using: calendar),
        state: dayState(on: date, activities: items),
        activities: items
      )
    }
  }

  var nextPlannedDay: ScheduledDay? {
    guard let tomorrow = calendar.date(
      byAdding: .day,
      value: 1,
      to: calendar.startOfDay(for: referenceDate)
    ) else { return nil }

    let skippedOccurrences = planOccurrences.filter(\.isSkipped)
    let nextOccurrences = plan.scheduledOccurrences(
      from: tomorrow,
      through: plan.endDate,
      calendar: calendar
    ).filter { generatedOccurrence in
      !skippedOccurrences.contains {
        $0.activityID == generatedOccurrence.activityID
          && calendar.isDate($0.date, inSameDayAs: generatedOccurrence.date)
      }
    }
    guard let date = nextOccurrences.first?.date,
          let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date))
    else { return nil }

    return ScheduledDay(
      id: weekday,
      title: date.formatted(template: "EEEEMMMd", calendar: calendar),
      state: .upcoming,
      activities: activityItems(on: date, fallback: nextOccurrences)
    )
  }

  var activityBreakdown: [ActivityBreakdown] {
    let activityOrder = Dictionary(
      uniqueKeysWithValues: orderedScheduledActivityIDs.enumerated().map { ($0.element, $0.offset) }
    )
    let occurrencesByActivity = Dictionary(grouping: planOccurrences, by: \.activityID)
    return occurrencesByActivity.compactMap { activityID, occurrences in
      guard let activity = activitiesByID[activityID] else { return nil }
      let completedCount = occurrences.filter { occurrence in
        occurrence.dayActivityID.flatMap { dayActivitiesByID[$0]?.isDone } ?? false
      }.count
      return ActivityBreakdown(
        activity: ActivityItem(
          id: activity.id,
          name: activity.name,
          isDone: false,
          isSkipped: false
        ),
        completedCount: completedCount,
        plannedCount: occurrences.count
      )
    }
    .sorted {
      let firstOrder = activityOrder[$0.id] ?? .max
      let secondOrder = activityOrder[$1.id] ?? .max
      if firstOrder == secondOrder {
        return $0.activity.name.localizedStandardCompare($1.activity.name) == .orderedAscending
      }
      return firstOrder < secondOrder
    }
  }

  private var planOccurrences: [PlanOccurrence] {
    occurrences
      .filter { $0.planID == plan.id }
      .deduplicatedByID()
  }

  private var orderedScheduledActivityIDs: [Activity.ID] {
    var seen = Set<Activity.ID>()
    return PlanWeekday.ordered(using: calendar).flatMap { weekday in
      plan.schedule
        .filter { $0.weekday == weekday }
        .sorted { $0.position < $1.position }
        .compactMap { seen.insert($0.activityID).inserted ? $0.activityID : nil }
    }
  }

  private var activitiesByID: [Activity.ID: Activity] {
    Dictionary(activities.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
  }

  private var dayActivitiesByID: [DayActivity.ID: DayActivity] {
    Dictionary(
      dayActivities.map { ($0.id, $0) },
      uniquingKeysWith: { current, latest in latest.isDone ? latest : current }
    )
  }

  private var currentWeekDates: [PlanWeekday: Date] {
    guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [:] }
    return (0..<7).reduce(into: [:]) { dates, offset in
      guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start),
            let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date))
      else { return }
      dates[weekday] = date
    }
  }

  private func activityItems(
    on date: Date,
    fallback: [PlanOccurrence]? = nil
  ) -> [ActivityItem] {
    let matchingOccurrences = (fallback ?? planOccurrences).filter {
      calendar.isDate($0.date, inSameDayAs: date)
    }
    if !matchingOccurrences.isEmpty {
      return matchingOccurrences.compactMap { occurrence in
        guard let activity = activitiesByID[occurrence.activityID] else { return nil }
        return ActivityItem(
          id: activity.id,
          name: activity.name,
          isDone: occurrence.dayActivityID.flatMap { dayActivitiesByID[$0]?.isDone } ?? false,
          isSkipped: occurrence.isSkipped
        )
      }
    }

    guard let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date)) else {
      return []
    }
    return plan.schedule
      .filter { $0.weekday == weekday }
      .sorted { $0.position < $1.position }
      .compactMap(activityItem(for:))
  }

  private func activityItem(for entry: PlanScheduleEntry) -> ActivityItem? {
    guard let activity = activitiesByID[entry.activityID] else { return nil }
    return ActivityItem(id: activity.id, name: activity.name, isDone: false, isSkipped: false)
  }

  private func dayState(on date: Date?, activities: [ActivityItem]) -> DayState? {
    guard let date else { return .upcoming }
    guard calendar.startOfDay(for: date) >= calendar.startOfDay(for: plan.startDate) else {
      return nil
    }
    if !activities.isEmpty, activities.allSatisfy(\.isSkipped) { return .skipped }
    if !activities.isEmpty, activities.allSatisfy(\.isDone) { return .done }
    if activities.contains(where: \.isDone) { return .partial }
    if calendar.isDate(date, inSameDayAs: referenceDate) { return .today }
    return date < calendar.startOfDay(for: referenceDate) ? .missed : .upcoming
  }
}
