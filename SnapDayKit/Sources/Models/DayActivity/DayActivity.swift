import Foundation

public struct DayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var date: Date?
  public var activity: Activity?
  public var name: String
  public var iconId: UUID?
  public var dueDate: Date?
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public var isGeneratedAutomatically: Bool
  public var tags: [Tag]
  public var labels: [ActivityLabel]
  public var dayActivityTasks: [DayActivityTask]
  public var reminderDate: Date?
  public var important: Bool
  public var position: Int
  public var share: DayActivityShare?

  // MARK: - Initialization

  public init(
    id: UUID,
    date: Date?,
    activity: Activity? = nil,
    name: String = "",
    iconId: UUID? = nil,
    dueDate: Date? = nil,
    doneDate: Date? = nil,
    duration: Int = .zero,
    overview: String? = nil,
    isGeneratedAutomatically: Bool,
    tags: [Tag] = [],
    labels: [ActivityLabel] = [],
    dayActivityTasks: [DayActivityTask] = [],
    reminderDate: Date? = nil,
    important: Bool = false,
    position: Int = -1,
    share: DayActivityShare? = nil
  ) {
    self.id = id
    self.date = date
    self.activity = activity
    self.name = name
    self.iconId = iconId
    self.dueDate = dueDate
    self.doneDate = doneDate
    self.duration = duration
    self.overview = overview
    self.isGeneratedAutomatically = isGeneratedAutomatically
    self.tags = tags
    self.labels = labels
    self.dayActivityTasks = dayActivityTasks
    self.reminderDate = reminderDate
    self.important = important
    self.position = position
    self.share = share
  }
}

extension DayActivity: DurationProtocol { }

extension DayActivity {
  public var isSavable: Bool {
    !isInvitation
  }

  public var isInvitation: Bool {
    share?.invitationId != nil
  }

  public var isDone: Bool {
    doneDate != nil
  }

  public var totalDuration: Int {
    duration + dayActivityTasks.reduce(into: Int.zero, { result, dayActivityTask in
      result += dayActivityTask.duration
    })
  }

  public func ordered(hideCompleted: Bool) -> [DayActivityTask] {
    dayActivityTasks
      .sorted(by: { $0.position < $1.position })
      .filter {
        hideCompleted ? !$0.isDone : true
      }
  }
}

extension DayActivity {

  public var hasCompletedSubtasksAndNotDone: Bool {
    doneDate == nil && hasCompletedSubtasks
  }

  public var hasIncompletedSubtasksAndDone: Bool {
    doneDate != nil && !hasCompletedSubtasks
  }

  public var hasCompletedSubtasks: Bool {
    dayActivityTasks.filter { !$0.isDone }.isEmpty
  }
}
