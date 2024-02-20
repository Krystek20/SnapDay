import Foundation
import ComposableArchitecture

public struct PeriodDateRangeCreator {

  // MARK: - Dependecies

  @Dependency(\.calendar) private var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func today(for date: Date) -> ClosedRange<Date>? {
    calendar.dayFormat(date)...calendar.dayFormat(date)
  }

  public func weekRange(for date: Date) -> ClosedRange<Date>? {
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let start = calendar.date(from: components) else { return nil }
    guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return nil }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }

  public func mounthRange(for date: Date) -> ClosedRange<Date>? {
    let components = calendar.dateComponents([.year, .month], from: date)
    guard let start = calendar.date(from: components) else { return nil }
    guard let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { return nil }
    return calendar.dayFormat(start)...calendar.dayFormat(end)
  }

  public func quarterlyRange(for date: Date) -> ClosedRange<Date>? {
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
