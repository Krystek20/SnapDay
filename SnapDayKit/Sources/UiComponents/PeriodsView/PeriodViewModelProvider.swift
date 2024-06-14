import Foundation
import Models
import Dependencies

public struct PeriodViewModelProvider {

  // MARK: - Dependecies

  @Dependency(\.calendar) var calendar
  @Dependency(\.uuid) var uuid

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func preparePeriodViewModel(from days: [Day], to period: Period) -> [PeriodViewModel] {
    let dictionary = days
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Int: [Day]](), { result, day in
        reduceDaysIntoCalendarComponentDictionary(&result, day: day, component: period.calendarComponent)
      })
    return dictionary
      .keys
      .sorted()
      .compactMap { component in
        reduceDaysIntoCalendarComponentDictionary(dictionary, component: component, period: period)
      }
  }

  // MARK: - Private

  private func reduceDaysIntoCalendarComponentDictionary(_ result: inout [Int: [Day]], day: Day, component: Calendar.Component) {
    let calendarComponent = calendar.component(component, from: day.date)
    if result[calendarComponent] == nil {
      result[calendarComponent] = [day]
    } else {
      result[calendarComponent]?.append(day)
    }
  }

  private func reduceDaysIntoCalendarComponentDictionary(_ dictionary: [Int: [Day]], component: Int, period: Period) -> PeriodViewModel? {
    guard let firstDay = dictionary[component]?.first,
          let lastDay = dictionary[component]?.last else { return nil }
    let days = dictionary[component] ?? []

    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM yyyy"
    let startDate = formatter.string(from: firstDay.date)
    let endDate = formatter.string(from: lastDay.date)

    return PeriodViewModel(
      id: uuid(),
      label: String(format: "%@ - %@", startDate, endDate),
      completedValue: days.completedValue,
      percent: days.percent
    )
  }
}
