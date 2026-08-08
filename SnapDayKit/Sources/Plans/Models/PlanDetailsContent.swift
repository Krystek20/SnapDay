import Foundation
import Models
import Utilities

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

    var title: String.LocalizationValue {
      switch self {
      case .done: "Done"
      case .partial: "Partly done"
      case .missed: "Missed"
      case .today: "Today"
      case .upcoming: "Upcoming"
      }
    }
  }

  struct HistoryDay: Equatable, Identifiable {
    enum State: Equatable {
      case done
      case partial
      case missed
      case rest
      case future
    }

    let date: Date
    let state: State

    var id: Date { date }
    var opensDashboard: Bool {
      state == .done || state == .partial || state == .missed
    }
  }

  struct HistoryMonth: Equatable, Identifiable {
    let month: Date
    let leadingBlankCount: Int
    let days: [HistoryDay]

    var id: Date { month }
  }

  struct HistorySummary: Equatable {
    let completedDays: Int
    let partialDays: Int
    let missedDays: Int
    let remainingDays: Int
    let completedTime: Int
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
      title: date.formatted(template: "EEEEMMMd", calendar: calendar),
      state: .upcoming,
      activities: activityItems(on: date, fallback: nextOccurrences)
    )
  }

  var historySummary: HistorySummary {
    let linkedDayActivityIDs = Set(planOccurrences.compactMap(\.dayActivityID))
    return HistorySummary(
      completedDays: historyDays.filter { $0.state == .done }.count,
      partialDays: historyDays.filter { $0.state == .partial }.count,
      missedDays: historyDays.filter { $0.state == .missed }.count,
      remainingDays: historyDays.filter { $0.state == .future }.count,
      completedTime: dayActivitiesByID.values
        .filter { linkedDayActivityIDs.contains($0.id) && $0.isDone }
        .reduce(0) { $0 + $1.totalDuration }
    )
  }

  var hasRecordedHistory: Bool {
    historyDays.contains { $0.state == .done || $0.state == .partial || $0.state == .missed }
  }

  var historyMonths: [HistoryMonth] {
    let groupedDays = Dictionary(grouping: historyDays) { day in
      calendar.dateInterval(of: .month, for: day.date)?.start ?? day.date
    }
    return groupedDays.keys.sorted().compactMap { month in
      guard let days = groupedDays[month]?.sorted(by: { $0.date < $1.date }),
            let firstDay = days.first
      else { return nil }
      let weekday = calendar.component(.weekday, from: firstDay.date)
      let leadingBlankCount = (weekday - calendar.firstWeekday + 7) % 7
      return HistoryMonth(
        month: month,
        leadingBlankCount: leadingBlankCount,
        days: days
      )
    }
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
        activity: ActivityItem(id: activity.id, name: activity.name, isDone: false),
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

  private var historyDays: [HistoryDay] {
    let startDate = calendar.startOfDay(for: plan.startDate)
    let endDate = calendar.startOfDay(for: plan.endDate)
    let referenceDay = calendar.startOfDay(for: referenceDate)
    guard startDate <= endDate else { return [] }

    var result: [HistoryDay] = []
    var date = startDate
    while date <= endDate {
      let matchingOccurrences = planOccurrences.filter { calendar.isDate($0.date, inSameDayAs: date) }
      let state: HistoryDay.State
      if matchingOccurrences.isEmpty {
        state = .rest
      } else {
        let completedCount = matchingOccurrences.filter { occurrence in
          occurrence.dayActivityID.flatMap { dayActivitiesByID[$0]?.isDone } ?? false
        }.count
        if completedCount == matchingOccurrences.count {
          state = .done
        } else if completedCount > 0 {
          state = .partial
        } else if date < referenceDay {
          state = .missed
        } else {
          state = .future
        }
      }
      result.append(HistoryDay(date: date, state: state))
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
      date = nextDate
    }
    return result
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
