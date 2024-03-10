import Foundation
import Models
import Dependencies

public struct ActivitiesPresentationTypeProvider {

  // MARK: - Dependecies

  @Dependency(\.calendar) var calendar
  @Dependency(\.uuid) var uuid

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func presentationType(for timePeriod: TimePeriod) throws -> ActivitiesPresentationType {
    switch timePeriod.type {
    case .day:
      .daysList(
        .single(day: try timePeriod.firstDay)
      )
    case .week:
      .daysList(
        .multi(
          days: prepareTimePeriods(from: timePeriod, to: .day).compactMap { $0.days.first }
        )
      )
    case .month:
      .calendar(
        try prepareCalendarItems(timePeriod: timePeriod)
      )
    case .quarter:
      .monthsList(
        prepareTimePeriods(from: timePeriod, to: .month)
      )
    }
  }

  // MARK: - Private

  private func prepareCalendarItems(timePeriod: TimePeriod) throws -> [CalendarItemType] {
    guard let firstDay = timePeriod.days.first,
          let dayOfWeek = calendar.dateComponents([.weekday], from: firstDay.date).weekday else { return [] }
    return calendarItems(timePeriod: timePeriod, dayOfWeek: dayOfWeek)
  }

  private func calendarItems(timePeriod: TimePeriod, dayOfWeek: Int) -> [CalendarItemType] {
    let weekdays = WeekdaysProvider(calendar: calendar).weekdays
    let weekdayIndex = weekdays.firstIndex(where: { $0.index == dayOfWeek }) ?? dayOfWeek

    var calendarItems = weekdays
      .map(\.name)
      .map(CalendarItemType.dayOfWeek)
    calendarItems += (0..<weekdayIndex).map(CalendarItemType.empty)
    calendarItems += timePeriod.days.map(CalendarItemType.day)
    return calendarItems
  }

  private func prepareTimePeriods(from timePeriod: TimePeriod, to period: Period) -> [TimePeriod] {
    let dictionary = timePeriod.days
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

  private func reduceDaysIntoCalendarComponentDictionary(_ result: inout [Int: [Day]], day: Day, component: Calendar.Component) {
    let calendarComponent = calendar.component(component, from: day.date)
    if result[calendarComponent] == nil {
      result[calendarComponent] = [day]
    } else {
      result[calendarComponent]?.append(day)
    }
  }

  private func reduceDaysIntoCalendarComponentDictionary(_ dictionary: [Int: [Day]], component: Int, period: Period) -> TimePeriod? {
    guard let firstDay = dictionary[component]?.first,
          let lastDay = dictionary[component]?.last else { return nil }
    return TimePeriod(
      id: uuid(),
      days: dictionary[component] ?? [],
      name: period.rawValue,
      type: period,
      dateRange: firstDay.date...lastDay.date
    )
  }
}
