import Foundation

public struct DayActivityTask: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let dayActivityId: UUID
  public var activityTask: ActivityTask?
  public var name: String
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public var reminderDate: Date?
  public var position: Int
  /// Represented by shared day activity task id
  public var invitationId: String?

  // MARK: - Initialization

  public init(
    id: UUID,
    dayActivityId: UUID,
    activityTask: ActivityTask? = nil,
    name: String = "",
    doneDate: Date? = nil,
    duration: Int = .zero,
    overview: String? = nil,
    reminderDate: Date? = nil,
    position: Int = -1,
    invitationId: String? = nil
  ) {
    self.id = id
    self.dayActivityId = dayActivityId
    self.activityTask = activityTask
    self.name = name
    self.doneDate = doneDate
    self.duration = duration
    self.overview = overview
    self.reminderDate = reminderDate
    self.position = position
    self.invitationId = invitationId
  }
}

extension DayActivityTask: DurationProtocol { }

extension DayActivityTask {
  public var isDone: Bool {
    doneDate != nil
  }
}
