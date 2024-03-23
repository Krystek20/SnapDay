import Foundation
import Models
import Dependencies
import Utilities

struct ReportDaysProvider: TodayProvidable {

  @Dependency(\.calendar) private var calendar

  // MARK: - Public

  func prepareReportDays(
    selectedFilterPeriod: FilterPeriod?,
    selectedActivity: Activity?,
    selectedLabel: ActivityLabel?,
    selectedTag: Tag?,
    days: [Day]
  ) -> [ReportDay] {
    var reportDays = [ReportDay]()

    switch selectedFilterPeriod {
    case .day, .week, .none:
      break
    case .month, .quarter, .custom:
      reportDays = preparePlaceholder(firstDay: days.first)
    }

    reportDays += days.map { day in
      let dayActivity: ReportDayActivity
      if let selectedActivity {
        dayActivity = prepareDayReportyActivity(
          selectedActivity: selectedActivity,
          selectedLabel: selectedLabel,
          selectedTag: selectedTag,
          day: day
        )
      } else {
        dayActivity = prepareTagReportyActivity(
          selectedTag: selectedTag,
          day: day
        )
      }
      let title = dayNumber(day.date, selectedFilterPeriod: selectedFilterPeriod)
      return ReportDay(
        id: title,
        title: title,
        dayActivity: dayActivity
      )
    }
    return reportDays
  }

  // MARK: - Private

  private func preparePlaceholder(firstDay: Day?) -> [ReportDay] {
    guard let firstDay,
          let dayOfWeek = calendar.dateComponents([.weekday], from: firstDay.date).weekday else { return [] }

    let weekdays = WeekdaysProvider(calendar: calendar).weekdays
    let weekdayIndex = weekdays.firstIndex(where: { $0.index == dayOfWeek }) ?? dayOfWeek

    return (0..<weekdayIndex).map {
      ReportDay(id: String($0), title: nil, dayActivity: .empty)
    }
  }

  private func prepareDayReportyActivity(
    selectedActivity: Activity,
    selectedLabel: ActivityLabel?,
    selectedTag: Tag?,
    day: Day
  ) -> ReportDayActivity {
    let activities = day.activities.filter { dayActivity in
      let areMatchedActivityAndTag = dayActivity.activity == selectedActivity && dayActivity.tags.contains(where: { $0 == selectedTag })
      return areMatchedActivityAndTag && (selectedLabel == nil || dayActivity.labels.contains { $0 == selectedLabel })
    }
    let state = prepareDayState(date: day.date, activities: activities)
    return .activity(state)
  }

  private func prepareTagReportyActivity(
    selectedTag: Tag?,
    day: Day
  ) -> ReportDayActivity {
    let activities = day.activities.filter { $0.tags.contains { $0 == selectedTag } }
    let state = prepareDayState(date: day.date, activities: activities)
    return .tag(state)
  }

  private func prepareDayState(date: Date, activities: [DayActivity]) -> ReportDayState {
    if activities.isEmpty {
      .notPlanned
    } else if date <= today {
      activities.filter(\.isDone).isEmpty
      ? .notDone
      : .done
    } else {
      .planned
    }
  }

  private func dayNumber(_ date: Date, selectedFilterPeriod: FilterPeriod?) -> String {
    let dateFormatter = DateFormatter()
    switch selectedFilterPeriod {
    case .day, .week, .month:
      dateFormatter.dateFormat = "dd"
    case .quarter, .custom, .none:
      dateFormatter.dateFormat = "dd.MM"
    }
    return dateFormatter.string(from: date)
  }

}
