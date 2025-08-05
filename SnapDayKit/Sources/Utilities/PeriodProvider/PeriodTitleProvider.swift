import Foundation
import Models
import Dependencies

public struct PeriodTitleProvider {

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func title(for period: Period, range: ClosedRange<Date>) -> String? {
    let formatter = DateFormatter(period: period)
    formatter.locale = .preferred
    switch period {
    case .day:
      return formatter.string(from: range.lowerBound)
    case .month:
      return try? calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound)
    case .week:
      return formatter.string(from: range.lowerBound) + " - " + formatter.string(from: range.upperBound)
    case .quarter:
      guard let lowerBound = try? calendar.monthName(range.lowerBound).capitalized + " " + formatter.string(from: range.lowerBound),
            let upperBound = try? calendar.monthName(range.upperBound).capitalized + " " + formatter.string(from: range.upperBound)
      else { return nil }
      return lowerBound + " - " + upperBound
    case .year:
      return formatter.string(from: range.lowerBound)
    }
  }
}

private extension DateFormatter {
  convenience init(period: Period) {
    self.init()
    switch period {
    case .day, .week:
      dateFormat = "d MMM yyyy"
    case .month, .quarter, .year:
      dateFormat = "yyyy"
    }
  }
}
