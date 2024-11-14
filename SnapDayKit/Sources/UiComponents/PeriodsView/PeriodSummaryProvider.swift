import Foundation
import Models
import Dependencies

public struct PeriodSummaryProvider {

  struct DaysWithOrder: Equatable {
    var days: [Day]
    let order: Int
  }

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.uuid) private var uuid

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func preparePeriodSummary(from days: [Day], to period: Period) -> PeriodSummaryData {
    var sortedComponent: [Int] = []
    let dictionary = days
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Int: [Day]](), { result, day in
        reduceDaysIntoCalendarComponentDictionary(
          &result,
          &sortedComponent,
          day: day,
          component: period.calendarComponent
        )
      })

    let periods = sortedComponent.compactMap { component in
      reduceDaysIntoCalendarComponentDictionary(dictionary, component: component, period: period)
    }

    let maxInRow = switch period {
    case .quarter:
      3
    case .week, .month, .year:
      6
    case .day:
      7
    }

    return PeriodSummaryData(
      periods: periods,
      isScrollable: periods.count > 7,
      maxInRow: maxInRow
    )
  }

  // MARK: - Private

  private func reduceDaysIntoCalendarComponentDictionary(
    _ result: inout [Int: [Day]],
    _ sortedComponent: inout [Int],
    day: Day,
    component: Calendar.Component
  ) {
    let calendarComponent = calendar.component(component, from: day.date)
    if result[calendarComponent] == nil {
      result[calendarComponent] = [day]
      sortedComponent.append(calendarComponent)
    } else {
      result[calendarComponent]?.append(day)
    }
  }

  private func reduceDaysIntoCalendarComponentDictionary(
    _ dictionary: [Int: [Day]],
    component: Int,
    period: Period
  ) -> PeriodSummary? {
    guard let label = prepareLabel(dictionary, component: component, period: period) else { return nil }
    let days = dictionary[component] ?? []

    let totalTime = days.count * 24 * 60
    let sleepTime = days.count * 8 * 60
    let totalAvailableTime = totalTime - sleepTime
    let optimalTime = Int(Double(totalAvailableTime) * 0.80)

    return PeriodSummary(
      id: uuid(),
      label: label,
      completedValue: days.completedValue,
      percent: days.percent,
      totalPlannedDuration: days.totalPlannedDuration,
      totalCompletedDuration: days.totalCompletedDuration,
      totalAvailableTime: totalAvailableTime,
      optimalTime: optimalTime
    )
  }

  private func prepareLabel(_ dictionary: [Int: [Day]], component: Int, period: Period) -> String? {
    guard let firstDay = dictionary[component]?.first else { return nil }

    let formatter = DateFormatter()

    switch period {
    case .day:
      formatter.dateFormat = "E"
    case .week:
      return "\(component)"
    case .month:
      formatter.dateFormat = "MMM"
    case .quarter:
      formatter.dateFormat = "QQQ"
    case .year:
      formatter.dateFormat = "YYYY"
    }

    return formatter.string(from: firstDay.date)
  }
}
