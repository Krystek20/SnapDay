import Foundation
import Models

struct PlanDetailsContent: Equatable {

  struct ActivityItem: Equatable, Identifiable {
    let id: Activity.ID
    let name: String
    let isDone: Bool
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
    case missed
    case today
    case upcoming

    var title: String {
      switch self {
      case .done: "Done"
      case .partial: "Partly done"
      case .missed: "Missed"
      case .today: "Today"
      case .upcoming: "Upcoming"
      }
    }
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

    let nextOccurrences = plan.scheduledOccurrences(
      from: tomorrow,
      through: plan.endDate,
      calendar: calendar
    )
    guard let date = nextOccurrences.first?.date,
          let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date))
    else { return nil }

    return ScheduledDay(
      id: weekday,
      title: date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
      state: .upcoming,
      activities: activityItems(on: date, fallback: nextOccurrences)
    )
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
    let matchingOccurrences = (fallback ?? occurrences).filter {
      calendar.isDate($0.date, inSameDayAs: date)
    }
    if !matchingOccurrences.isEmpty {
      return matchingOccurrences.compactMap { occurrence in
        guard let activity = activitiesByID[occurrence.activityID] else { return nil }
        return ActivityItem(
          id: activity.id,
          name: activity.name,
          isDone: occurrence.dayActivityID.flatMap { dayActivitiesByID[$0]?.isDone } ?? false
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
    return ActivityItem(id: activity.id, name: activity.name, isDone: false)
  }

  private func dayState(on date: Date?, activities: [ActivityItem]) -> DayState? {
    guard let date else { return .upcoming }
    guard calendar.startOfDay(for: date) >= calendar.startOfDay(for: plan.startDate) else {
      return nil
    }
    if !activities.isEmpty, activities.allSatisfy(\.isDone) { return .done }
    if activities.contains(where: \.isDone) { return .partial }
    if calendar.isDate(date, inSameDayAs: referenceDate) { return .today }
    return date < calendar.startOfDay(for: referenceDate) ? .missed : .upcoming
  }
}
