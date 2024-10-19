import Foundation

public protocol ActivityType {
  var id: UUID { get }
  var name: String { get }
  var icon: Icon? { get }
  var doneDate: Date? { get }
  var duration: Int { get }
  var overview: String? { get }
  var reminderDate: Date? { get }
  var dueDate: Date? { get }
  var dueDaysCount: Int? { get }
  var isFrequentEnabled: Bool { get }
  var important: Bool { get }
  var position: Int { get set }
}

extension ActivityType {
  public var isDone: Bool {
    doneDate != nil
  }
}

extension DayActivity: ActivityType {
  public var dueDaysCount: Int? { nil }
  public var isFrequentEnabled: Bool { false }
}

extension DayActivityTask: ActivityType {
  public var dueDate: Date? { nil }
  public var dueDaysCount: Int? { nil }
  public var isFrequentEnabled: Bool { false }
  public var important: Bool { false }
}

extension Activity: ActivityType {
  public var doneDate: Date? { nil }
  public var dueDate: Date? { nil }
  public var duration: Int { defaultDuration ?? .zero }
  public var overview: String? { nil }
  public var reminderDate: Date? { defaultReminderDate }
  public var position: Int {
    get { -1 }
    set { }
  }
}

extension Array where Element: ActivityType {
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

extension ActivityType {
  public func priority(calendar: Calendar) -> ActivityPriority {
    if isDone {
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

public enum ActivityPriority: Int, CaseIterable, Comparable {
  case urgent
  case critical
  case important
  case normal
  case low

  public static func < (lhs: ActivityPriority, rhs: ActivityPriority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

