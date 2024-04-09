import Models
import UiComponents

extension Activity: DefaultDurationProtocol {
  var isActivityReadyToSave: Bool {
    let isRepeatableSet: Bool
    switch frequency {
    case .daily:
      isRepeatableSet = true
    case .weekly(let days):
      isRepeatableSet = !days.isEmpty
    case .biweekly(let days, _):
      isRepeatableSet = !days.isEmpty
    case .monthly(.monthlySpecificDate(let days)):
      isRepeatableSet = !days.isEmpty
    case .monthly(monthlySchedule: .weekdayOrdinal(let weekdayOrdinals)):
      isRepeatableSet = !weekdayOrdinals.reduce(into: [Int](), { result, weekdayOrdinal in
        result.append(contentsOf: weekdayOrdinal.weekdays)
      }).isEmpty
    case .monthly:
      isRepeatableSet = true
    case .none:
      isRepeatableSet = true
    }
    return !name.isEmpty && isRepeatableSet
  }

  mutating func setIsRepeatable(_ isRepeatable: Bool) {
    frequency = isRepeatable ? .daily : nil
  }

  var areWeekdaysRequried: Bool {
    switch frequency {
    case .weekly: true
    case .biweekly: true
    default: false
    }
  }

  var areMonthlyScheduleRequried: Bool {
    switch frequency {
    case .monthly: true
    default: false
    }
  }

  var areMonthDaysRequried: Bool {
    switch frequency {
    case .monthly(.monthlySpecificDate): true
    default: false
    }
  }
  
  var areMonthWeekdaysRequried: Bool {
    switch frequency {
    case .monthly(.weekdayOrdinal): true
    default: false
    }
  }

  var weekdays: [Int] {
    switch frequency {
    case .weekly(let days):
      days
    case .biweekly(let days, _):
      days
    default:
      []
    }
  }

  mutating func setWeekdays(_ weekdays: [Int]) {
    switch frequency {
    case .weekly:
      frequency = .weekly(days: weekdays)
    case .biweekly:
      frequency = .biweekly(days: weekdays, startWeek: .current)
    default:
      break
    }
  }

  var monthlySchedule: MonthlySchedule? {
    switch frequency {
    case .monthly(let monthlySchedule): monthlySchedule
    default: nil
    }
  }

  mutating func setMonthlySchedule(_ monthlySchedule: MonthlySchedule?) {
    guard let monthlySchedule else { return }
    frequency = .monthly(monthlySchedule: monthlySchedule)
  }

  var mounthDays: [Int] {
    switch frequency {
    case .monthly(monthlySchedule: .monthlySpecificDate(let days)): days
    default: []
    }
  }

  mutating func setMounthDays(_ days: [Int]) {
    frequency = .monthly(monthlySchedule: .monthlySpecificDate(days))
  }

  var weekdayOrdinal: [WeekdayOrdinal] {
    switch frequency {
    case .monthly(.weekdayOrdinal(let weekdayOrdinal)): weekdayOrdinal
    default: []
    }
  }

  mutating func setWeekdayOrdinal(_ weekdayOrdinal: [WeekdayOrdinal]) {
    frequency = .monthly(monthlySchedule: .weekdayOrdinal(weekdayOrdinal))
  }
}
