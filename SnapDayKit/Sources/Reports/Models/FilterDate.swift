import Foundation
import Utilities
import Models

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
