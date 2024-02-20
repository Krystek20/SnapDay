import Foundation
import Dependencies
import Utilities

enum FilterDate: Equatable {
  case singleDay(Date)
  case singleMonth(ClosedRange<Date>)
  case dateRange(ClosedRange<Date>)
  case monthsRange(ClosedRange<Date>)
}

extension FilterDate {
  init?(filter: FilterPeriod?, lowerBound: Date, upperBound: Date?) {
    guard let filter else { return nil }
    let periodDateRangeCreator = PeriodDateRangeCreator()
    switch filter {
    case .day:
      self = .singleDay(lowerBound)
    case .week:
      guard let range = periodDateRangeCreator.weekRange(for: lowerBound) else { return nil }
      self = .dateRange(range)
    case .month:
      guard let range = periodDateRangeCreator.mounthRange(for: lowerBound) else { return nil }
      self = .singleMonth(range)
    case .quarter:
      guard let range = periodDateRangeCreator.quarterlyRange(for: lowerBound) else { return nil }
      self = .monthsRange(range)
    case .custom:
      guard let upperBound else { return nil }
      self = .dateRange(lowerBound...upperBound)
    }
  }
}

extension FilterDate {
  var title: String {
    let formatter = DateFormatter(filterDate: self)
    @Dependency(\.calendar) var calendar
    switch self {
    case .singleDay(let date):
      return formatter.string(from: date)
    case .singleMonth(let range):
      do {
        return try calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound)
      } catch {
        return ""
      }
    case .dateRange(let range):
      return formatter.string(from: range.lowerBound) + " - " + formatter.string(from: range.upperBound)
    case .monthsRange(let range):
      do {
        let lowerBound = try calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound)
        let upperBound = try calendar.monthName(range.upperBound).capitalized + " " + formatter.string(from: range.upperBound)
        return lowerBound + " - " + upperBound
      } catch {
        return ""
      }
    }
  }

  var range: ClosedRange<Date> {
    switch self {
    case .singleDay(let date):
      date...date
    case .singleMonth(let closedRange), .dateRange(let closedRange), .monthsRange(let closedRange):
      closedRange
    }
  }

  func setStartDate(_ value: Date) -> FilterDate {
    switch self {
    case .singleDay:
      .singleDay(value)
    case .singleMonth(let closedRange):
      .singleMonth(value...closedRange.upperBound)
    case .dateRange(let closedRange):
      .dateRange(value...closedRange.upperBound)
    case .monthsRange(let closedRange):
      .monthsRange(value...closedRange.upperBound)
    }
  }

  func setEndDate(_ value: Date) -> FilterDate {
    switch self {
    case .singleDay:
      .singleDay(value)
    case .singleMonth(let closedRange):
      .singleMonth(closedRange.lowerBound...value)
    case .dateRange(let closedRange):
      .dateRange(closedRange.lowerBound...value)
    case .monthsRange(let closedRange):
      .monthsRange(closedRange.lowerBound...value)
    }
  }
}

private extension DateFormatter {
  convenience init(filterDate: FilterDate) {
    self.init()
    switch filterDate {
    case .singleDay:
      dateFormat = "EEEE, d MMM yyyy"
    case .dateRange:
      dateFormat = "d MMM yyyy"
    case .monthsRange, .singleMonth:
      dateFormat = "yyyy"
    }
  }
}
