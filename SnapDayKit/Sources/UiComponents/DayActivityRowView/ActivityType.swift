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
}

extension ActivityType {
  public var isDone: Bool {
    doneDate != nil
  }
}

extension DayActivity: ActivityType { }
extension DayActivityTask: ActivityType { 
  public var dueDate: Date? { nil }
}
extension Activity: ActivityType {
  public var doneDate: Date? { nil }
  public var dueDate: Date? { nil }
  public var duration: Int { defaultDuration ?? .zero }
  public var overview: String? { nil }
  public var reminderDate: Date? { defaultReminderDate }
}
