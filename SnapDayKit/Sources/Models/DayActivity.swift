import Foundation

public struct DayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var dayId: UUID
  public var activity: Activity?
  public var name: String
  public var icon: Icon?
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public var isGeneratedAutomatically: Bool
  public var tags: [Tag]
  public var labels: [ActivityLabel]
  public var dayActivityTasks: [DayActivityTask]
  public var reminderDate: Date?

  // MARK: - Initialization

  public init(
    id: UUID,
    dayId: UUID,
    activity: Activity? = nil,
    name: String = "",
    icon: Icon? = nil,
    doneDate: Date? = nil,
    duration: Int = .zero,
    overview: String? = nil,
    isGeneratedAutomatically: Bool,
    tags: [Tag] = [],
    labels: [ActivityLabel] = [],
    dayActivityTasks: [DayActivityTask] = [],
    reminderDate: Date? = nil
  ) {
    self.id = id
    self.dayId = dayId
    self.activity = activity
    self.name = name
    self.icon = icon
    self.doneDate = doneDate
    self.duration = duration
    self.overview = overview
    self.isGeneratedAutomatically = isGeneratedAutomatically
    self.tags = tags
    self.labels = labels
    self.dayActivityTasks = dayActivityTasks
    self.reminderDate = reminderDate
  }
}

extension DayActivity: DurationProtocol { }

extension DayActivity {
  public var isDone: Bool {
    doneDate != nil
  }

  public var totalDuration: Int {
    duration + dayActivityTasks.reduce(into: Int.zero, { result, dayActivityTask in
      result += dayActivityTask.duration
    })
  }

  public var toDoTasks: [DayActivityTask] {
    dayActivityTasks.filter { !$0.isDone }
  }
}

extension DayActivity {
  public var hasIncompleteSubtasksAndNotDone: Bool {
    return doneDate == nil && hasIncompleteSubtasks
  }

  private var hasIncompleteSubtasks: Bool {
    !dayActivityTasks.filter { !$0.isDone }.isEmpty
  }

  public func areSubtasksCompleted(excluding dayActivityTask: DayActivityTask) -> Bool {
    let areAllSubtasksDone = dayActivityTasks
      .filter { $0.id != dayActivityTask.id && !$0.isDone }
      .isEmpty
    return dayActivityTask.doneDate == nil && doneDate == nil && areAllSubtasksDone
  }
}
