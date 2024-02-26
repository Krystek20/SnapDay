import Foundation
import Models
import Dependencies
import Utilities

struct ReportDaysProvider {

  @Dependency(\.calendar) private var calendar

  // MARK: - Public

  func prepareReportDays(
    selectedFilterPeriod: FilterPeriod?,
    selectedActivity: Activity?,
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
        dayActivity = prepareDayReportyActivity(selectedActivity: selectedActivity, dayActivities: day.activities)
      } else {
        dayActivity = prepareTagReportyActivity(selectedTag: selectedTag, dayActivities: day.activities)
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

  private func prepareDayReportyActivity(selectedActivity: Activity, dayActivities: [DayActivity]) -> ReportDayActivity {
    let activities = dayActivities.filter { $0.activity == selectedActivity }
    return activities.isEmpty
    ? .notPlanned
    : .activity(activities.contains(where: { $0.isDone }))
  }

  private func prepareTagReportyActivity(selectedTag: Tag?, dayActivities: [DayActivity]) -> ReportDayActivity {
    let activities = dayActivities
      .filter { $0.activity.tags.contains { $0 == selectedTag } && $0.isDone }
    return .tag(!activities.isEmpty)
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
