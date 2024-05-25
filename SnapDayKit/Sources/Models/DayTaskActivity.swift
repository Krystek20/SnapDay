import Foundation

public struct DayActivityTask: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let dayActivityId: UUID
  public var activityTask: ActivityTask?
  public var name: String
  public var icon: Icon?
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public var reminderDate: Date?

  // MARK: - Initialization

  public init(
    id: UUID,
    dayActivityId: UUID,
    activityTask: ActivityTask? = nil,
    name: String = "",
    icon: Icon? = nil,
    doneDate: Date? = nil,
    duration: Int = .zero,
    overview: String? = nil,
    reminderDate: Date? = nil
  ) {
    self.id = id
    self.dayActivityId = dayActivityId
    self.activityTask = activityTask
    self.name = name
    self.icon = icon
    self.doneDate = doneDate
    self.duration = duration
    self.overview = overview
    self.reminderDate = reminderDate
  }
}

extension DayActivityTask: DurationProtocol { }

extension DayActivityTask {
  public var isDone: Bool {
    doneDate != nil
  }
}
