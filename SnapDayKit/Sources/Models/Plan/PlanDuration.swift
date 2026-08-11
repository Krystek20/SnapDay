import Foundation

public enum PlanDuration: String, CaseIterable, Equatable, Hashable, Identifiable {
  case sevenDays
  case twoWeeks
  case oneMonth
  case threeMonths
  case sixMonths
  case oneYear
  case custom

  public var id: Self { self }

  public func endDate(
    from startDate: Date,
    calendar: Calendar = .autoupdatingCurrent
  ) -> Date {
    switch self {
    case .sevenDays:
      calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
    case .twoWeeks:
      calendar.date(byAdding: .day, value: 13, to: startDate) ?? startDate
    case .oneMonth:
      inclusiveEndDate(byAdding: .month, value: 1, to: startDate, calendar: calendar)
    case .threeMonths:
      inclusiveEndDate(byAdding: .month, value: 3, to: startDate, calendar: calendar)
    case .sixMonths:
      inclusiveEndDate(byAdding: .month, value: 6, to: startDate, calendar: calendar)
    case .oneYear:
      inclusiveEndDate(byAdding: .year, value: 1, to: startDate, calendar: calendar)
    case .custom:
      startDate
    }
  }

  private func inclusiveEndDate(
    byAdding component: Calendar.Component,
    value: Int,
    to startDate: Date,
    calendar: Calendar
  ) -> Date {
    guard let exclusiveEnd = calendar.date(byAdding: component, value: value, to: startDate) else {
      return startDate
    }
    return calendar.date(byAdding: .day, value: -1, to: exclusiveEnd) ?? startDate
  }
}
