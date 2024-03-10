import Foundation
import Models

extension FilterDate {
  init(type: ActivitiesPresentationType, dateRange: ClosedRange<Date>) {
    switch type {
    case .monthsList:
      self = .monthsRange(dateRange)
    case .calendar:
      self = .singleMonth(dateRange)
    case .daysList(let style):
      switch style {
      case .single:
        self = .singleDay(dateRange.lowerBound)
      case .multi:
        self = .dateRange(dateRange)
      }
    }
  }
}
