import Foundation
import Models

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
}
extension Activity: ActivityType {
  public var doneDate: Date? { nil }
  public var dueDate: Date? { nil }
  public var duration: Int { defaultDuration ?? .zero }
  public var overview: String? { nil }
  public var reminderDate: Date? { defaultReminderDate }
}

extension Array where Element: ActivityType {
  public var sorted: [Element] {
    sorted(by: {
      if $0.isDone == $1.isDone { return $0.name < $1.name }
      return !$0.isDone && $1.isDone
    })
  }
}
