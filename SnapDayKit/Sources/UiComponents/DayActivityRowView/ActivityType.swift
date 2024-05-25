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
}

extension ActivityType {
  public var isDone: Bool {
    doneDate != nil
  }
}

extension DayActivity: ActivityType { }
extension DayActivityTask: ActivityType { }
