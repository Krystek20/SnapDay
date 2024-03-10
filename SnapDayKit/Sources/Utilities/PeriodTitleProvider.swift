import Foundation
import Models
import Dependencies

public struct PeriodTitleProvider {

  // MARK: - Dependecies

  @Dependency(\.calendar) var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func title(for filterDate: FilterDate) throws -> String {
    let formatter = DateFormatter(filterDate: filterDate)
    switch filterDate {
    case .singleDay(let date):
      return formatter.string(from: date)
    case .singleMonth(let range):
      return try calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound)
    case .dateRange(let range):
      return formatter.string(from: range.lowerBound) + " - " + formatter.string(from: range.upperBound)
    case .monthsRange(let range):
      let lowerBound = try calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound)
      let upperBound = try calendar.monthName(range.upperBound).capitalized + " " + formatter.string(from: range.upperBound)
      return lowerBound + " - " + upperBound
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
