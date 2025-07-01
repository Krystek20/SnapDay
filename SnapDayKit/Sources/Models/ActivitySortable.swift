import Foundation

extension DayActivity: ActivitySortable { }

public protocol ActivitySortable {
  var name: String { get }
  var position: Int { get set }
  var dueDate: Date? { get }
  var doneDate: Date? { get }
  var important: Bool { get }
}

extension Array where Element: ActivitySortable {
  public func sorted(calendar: Calendar) -> [Element] {
    var sorted = sorted(by: {
      if $0.priority(calendar: calendar) != $1.priority(calendar: calendar) {
        return $0.priority(calendar: calendar) < $1.priority(calendar: calendar)
      }

      if $0.position != -1 && $1.position != -1 {
          return $0.position < $1.position
      } else if $0.position != -1 {
          return true
      } else if $1.position != -1 {
          return false
      }

      return $0.name < $1.name
    })

    for index in sorted.indices {
      sorted[index].position = index
    }

    return sorted
  }
}

extension ActivitySortable {
  public func priority(calendar: Calendar) -> Priority {
    if doneDate != nil {
      .low
    } else if let dueDate, calendar.isDateInToday(dueDate), important {
      .urgent
    } else if let dueDate, calendar.isDateInTomorrow(dueDate), important {
      .critical
    } else if important {
      .important
    } else {
      .normal
    }
  }
}

public enum Priority: Int, CaseIterable, Comparable {
  case urgent
  case critical
  case important
  case normal
  case low

  public static func < (lhs: Priority, rhs: Priority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
