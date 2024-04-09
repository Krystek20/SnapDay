import Foundation

public struct DayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var activity: Activity
  public var name: String
  public var icon: Icon?
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public let isGeneratedAutomatically: Bool
  public var tags: [Tag]
  public var labels: [ActivityLabel]
  public var dayActivityTasks: [DayActivityTask]

  // MARK: - Initialization

  public init(
    id: UUID,
    activity: Activity,
    name: String,
    icon: Icon?,
    doneDate: Date?,
    duration: Int,
    overview: String?,
    isGeneratedAutomatically: Bool,
    tags: [Tag],
    labels: [ActivityLabel],
    dayActivityTasks: [DayActivityTask]
  ) {
    self.id = id
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
