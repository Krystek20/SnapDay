import Foundation
import Dependencies
import Models

public struct PeriodDateRangeCreator: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func prepareClosedRange(
    for period: Period,
    periodShift: Int
  ) -> ClosedRange<Date>? {
    let shiftDate = shiftDate(for: period, periodShift: periodShift)
    return switch period {
    case .day:
      shiftDate...shiftDate
    case .week:
      weekRange(for: shiftDate)
    case .month:
      mounthRange(for: shiftDate)
    case .quarter:
      quarterlyRange(for: shiftDate)
    case .year:
      yearRange(for: shiftDate)
    }
  }

  // MARK: - Private

  private func shiftDate(for period: Period, periodShift: Int) -> Date {
    switch period {
    case .day:
      return calendar.date(byAdding: .day, value: periodShift, to: today) ?? today
    case .week:
      let shift = periodShift != .zero ? periodShift * 7 : .zero
      return calendar.date(byAdding: .day, value: shift, to: today) ?? today
    case .month:
      return calendar.date(byAdding: .month, value: periodShift, to: today) ?? today
    case .quarter:
      let shift = periodShift != .zero ? periodShift * 3 : .zero
      return calendar.date(byAdding: .month, value: shift, to: today) ?? today
    case .year:
      return calendar.date(byAdding: .year, value: periodShift, to: today) ?? today
    }
  }

  private func dayRange(for date: Date) -> ClosedRange<Date>? {
    calendar.dayFormat(date)...calendar.dayFormat(date)
  }

  private func weekRange(for date: Date) -> ClosedRange<Date>? {
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let start = calendar.date(from: components) else { return nil }
    guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return nil }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }

  private func mounthRange(for date: Date) -> ClosedRange<Date>? {
    let components = calendar.dateComponents([.year, .month], from: date)
    guard let start = calendar.date(from: components) else { return nil }
    guard let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { return nil }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }

  private func quarterlyRange(for date: Date) -> ClosedRange<Date>? {
    guard let start = calendar.startQuarterDay(fromDate: date),
          let endMonth = calendar.date(byAdding: .month, value: 2, to: start) else { return nil }
    let endDateComponents = DateComponents(
      year: calendar.component(.year, from: date),
      month: calendar.component(.month, from: endMonth),
      day: calendar.range(of: .day, in: .month, for: endMonth)?.count
    )
    guard let end = calendar.date(from: endDateComponents) else { return nil }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }

  private func yearRange(for date: Date) -> ClosedRange<Date>? {
    var startComponents = calendar.dateComponents([.year], from: date)
    startComponents.month = 1
    startComponents.day = 1

    var endComponents = calendar.dateComponents([.year], from: date)
    endComponents.month = 12
    endComponents.day = 31

    guard let start = calendar.date(from: startComponents),
          let end = calendar.date(from: endComponents) else {
      return nil
    }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }
}

private extension Calendar {
  func startQuarterDay(fromDate: Date) -> Date? {
    let quarterMonthRanges = stride(from: 1, to: 12, by: 3).map { $0..<$0 + 3 }
    let currentMonth = component(.month, from: fromDate)
    let startQuarterMonth = quarterMonthRanges.first(where: { $0.contains(currentMonth) })?.lowerBound
    let components = DateComponents(year: component(.year, from: fromDate), month: startQuarterMonth, day: 1)
    return date(from: components)
  }
}
