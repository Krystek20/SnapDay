import Foundation
import Models
import Dependencies
import Utilities

public struct ReportDaysProvider: TodayProvidable {

  public enum ReportDaysMode {
    case tag(Tag, Activity?)
    case activity(Activity, ActivityLabel?)
  }

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func prepareReportDays(
    period: Period,
    reportType: ReportType,
    days: [Day]
  ) -> [ReportDaysSection] {

    func prepareReportDays(days: [Day]) -> [ReportDay] {
      days.map { day in
        let reportDayActivity = switch reportType {
        case .activity(let activity, _, let activityLabel):
          prepareDayReportyActivity(activity: activity, label: activityLabel, day: day)
        case .tag(let tag, _, let activity):
          prepareTagReportyActivity(tag: tag, activity: activity, day: day)
        }

        return ReportDay(
          id: day.id.uuidString,
          title: dayNumber(day.date),
          dayActivity: reportDayActivity
        )
      }
    }

    return switch period {
    case .day:
      []
    case .week:
      [
        ReportDaysSection(
          id: period.id,
          title: nil,
          items: prepareReportDays(days: days)
        )
      ]
    case .month:
      [
        ReportDaysSection(
          id: period.id,
          title: nil,
          items: preparePlaceholder(firstDay: days.first) + prepareReportDays(days: days)
        )
      ]
    case .quarter, .year:
      Dictionary(grouping: days) { day in
        calendar.component(.month, from: day.date)
      }
      .sorted(by: { $0.key < $1.key })
      .map { monthKey, days in
        ReportDaysSection(
          id: calendar.standaloneMonthSymbols[monthKey - 1],
          title: calendar.standaloneMonthSymbols[monthKey - 1].capitalized,
          items: preparePlaceholder(firstDay: days.first) + prepareReportDays(days: days)
        )
      }
    }
  }

  // MARK: - Private

  private func preparePlaceholder(firstDay: Day?) -> [ReportDay] {
    guard let firstDay, let dayOfWeek = calendar.dateComponents([.weekday], from: firstDay.date).weekday else { return [] }

    let weekdays = WeekdaysProvider().weekdays
    let weekdayIndex = weekdays.firstIndex(where: { $0.index == dayOfWeek }) ?? dayOfWeek

    return (0..<weekdayIndex).map {
      ReportDay(id: String($0), title: nil, dayActivity: .empty)
    }
  }

  private func prepareDayReportyActivity(
    activity: Activity,
    label: ActivityLabel?,
    day: Day
  ) -> ReportDayActivity {
    let activities = day.activities.filter {
      $0.activity?.id == activity.id && (label == nil || $0.labels.contains { $0 == label })
    }
    let state = prepareDayState(date: day.date, activities: activities)
    return .activity(state, activity.iconId)
  }

  private func prepareTagReportyActivity(
    tag: Tag,
    activity: Activity?,
    day: Day
  ) -> ReportDayActivity {
    let activities = day.activities.filter {
      $0.activity?.tags.contains(where: { $0 == tag }) == true && (activity == nil || $0.activity?.id == activity?.id)
    }
    let state = prepareDayState(date: day.date, activities: activities)
    return .tag(state, tag.rgbColor)
  }

  private func prepareDayState(date: Date, activities: [DayActivity]) -> ReportDayState {
    if activities.isEmpty {
      .notPlanned
    } else if date < today {
      activities.filter(\.isDone).isEmpty ? .notDone : .done
    } else if date == today {
      activities.filter(\.isDone).isEmpty ? .planned : .done
    } else {
      .planned
    }
  }

  private func dayNumber(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd"
    return dateFormatter.string(from: date)
  }
}
