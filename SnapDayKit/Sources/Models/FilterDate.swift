import Foundation

public enum FilterDate: Equatable {
  case singleDay(Date)
  case singleMonth(ClosedRange<Date>)
  case dateRange(ClosedRange<Date>)
  case monthsRange(ClosedRange<Date>)
}
