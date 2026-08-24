#if DEBUG
import ComposableArchitecture
import Models
import SwiftUI

#Preview("Active - Today") {
  PlanDetailsPreview.view(.activeToday)
}

#Preview("Active - Rest Day") {
  PlanDetailsPreview.view(.activeRestDay)
}

#Preview("Finished") {
  PlanDetailsPreview.view(.finished)
}

#Preview("Archived") {
  PlanDetailsPreview.view(.archived)
}

#Preview("Finished - No Completions") {
  PlanDetailsPreview.view(.finishedNoCompletions)
}

#Preview("Archived - Restorable") {
  PlanDetailsPreview.view(.archivedRestorable)
}

@MainActor
private enum PlanDetailsPreview {
  case activeToday
  case activeRestDay
  case finished
  case finishedNoCompletions
  case archived
  case archivedRestorable

  static func view(_ preview: Self) -> some View {
    NavigationStack {
      PlanDetailsView(
        store: Store(initialState: preview.state) {
          PlanDetailsFeature()
        }
      )
    }
    .environment(\.calendar, calendar)
  }

  var state: PlanDetailsFeature.State {
    let referenceDate = Self.date(day: 15)
    let read = Activity(id: UUID(), name: "Read 20 minutes")
    let walk = Activity(id: UUID(), name: "Evening walk")
    let activities = [read, walk]
    let weekdays: [PlanWeekday] = self == .activeRestDay
      ? [.monday, .wednesday, .friday]
      : [.tuesday, .wednesday, .thursday, .saturday]
    let schedule = weekdays.flatMap { weekday in
      activities.enumerated().map { index, activity in
        PlanScheduleEntry(
          id: UUID(),
          weekday: weekday,
          activityID: activity.id,
          position: index
        )
      }
    }

    let statusDates: (start: Date, end: Date, archived: Bool) = switch self {
    case .activeToday, .activeRestDay:
      (Self.date(day: 1), Self.date(day: 31), false)
    case .finished, .finishedNoCompletions:
      (Self.date(month: 6, day: 1), Self.date(month: 6, day: 30), false)
    case .archived:
      (Self.date(month: 5, day: 1), Self.date(month: 5, day: 31), true)
    case .archivedRestorable:
      (Self.date(day: 1), Self.date(day: 31), true)
    }
    let plan = Plan(
      id: UUID(),
      name: self == .archived || self == .archivedRestorable ? "Morning reset" : "Learn Spanish",
      startDate: statusDates.start,
      endDate: statusDates.end,
      duration: .custom,
      isArchived: statusDates.archived,
      schedule: schedule
    )

    let plannedOccurrences = plan.scheduledOccurrences(calendar: Self.calendar)
    let completedCount: Int = switch self {
    case .activeToday, .activeRestDay: 7
    case .finished: 13
    case .finishedNoCompletions: 0
    case .archived, .archivedRestorable: 6
    }
    let linkedOccurrences = plannedOccurrences.enumerated().map { index, occurrence in
      let isSkipped = self == .activeToday
        && Self.calendar.isDate(occurrence.date, inSameDayAs: referenceDate)
        && occurrence.activityID == walk.id
      return PlanOccurrence(
        planID: occurrence.planID,
        activityID: occurrence.activityID,
        date: occurrence.date,
        dayActivityID: !isSkipped && index < completedCount ? UUID() : nil,
        isSkipped: isSkipped
      )
    }
    let dayActivities = linkedOccurrences.compactMap { occurrence -> DayActivity? in
      guard let dayActivityID = occurrence.dayActivityID,
            let activity = activities.first(where: { $0.id == occurrence.activityID })
      else { return nil }
      return DayActivity(
        id: dayActivityID,
        date: occurrence.date,
        activity: activity,
        name: activity.name,
        doneDate: occurrence.date,
        duration: 0,
        isGeneratedAutomatically: true
      )
    }

    return PlanDetailsFeature.State(
      plan: plan,
      allowsManagement: true,
      activities: activities,
      occurrences: linkedOccurrences,
      dayActivities: dayActivities,
      referenceDate: referenceDate
    )
  }

  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US")
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    calendar.firstWeekday = 2
    return calendar
  }()

  private static func date(month: Int = 7, day: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)) ?? .now
  }
}
#endif
