import Foundation
import Dependencies
import Models

public enum DayActivityFormId: String {
  case parentId
  case templateId
  case dayId
}

public enum DayActivityFormType: Equatable {
  case template
  case templateTask
  case activity(showCompleted: Bool)
  case activityTask(showCompleted: Bool)
}

public struct DayActivityForm: Equatable, Identifiable, DurationProtocol, FrequencyProtocol {
  public var id: UUID
  public var ids: [DayActivityFormId: UUID]
  public var completed: Bool
  public var icon: Icon?
  public var name: String
  public var tags: [Tag]
  public var frequency: ActivityFrequency?
  public var duration: Int
  public var reminderDate: Date?
  public var overview: String
  public var tasks: [DayActivityForm]
  public var labels: [ActivityLabel]
  public let type: DayActivityFormType
}

extension DayActivityForm {
  var fields: [DayActivityField] {
    switch type {
    case .activity(let showCompleted):
      [
        showCompleted ? .completed : nil,
        .icon,
        .name,
        .tags,
        .duration,
        .reminder,
        .overview,
        ids[.templateId] != nil ? .labels : nil,
        .tasks
      ].compactMap { $0 }
    case .activityTask(let showCompleted):
      [
        showCompleted ? .completed : nil,
        .icon,
        .name,
        .duration,
        .reminder,
        .overview
      ].compactMap { $0 }
    case .template:
      [
        .icon,
        .name,
        .tags,
        .frequency,
        .duration,
        .reminder,
        .overview,
        .tasks
      ]
    case .templateTask:
      [
        .icon,
        .name,
        .duration,
        .reminder
      ]
    }
  }

  var requriedFields: [DayActivityField] {
    switch type {
    case .activity:
      [.name]
    case .activityTask:
      [.name]
    case .template:
      [.name, .frequency]
    case .templateTask:
      [.name]
    }
  }

  var newTitle: String {
    switch type {
    case .activity:
      String(localized: "New Activity", bundle: .module)
    case .activityTask:
      String(localized: "New Activity Task", bundle: .module)
    case .template:
      String(localized: "New Template", bundle: .module)
    case .templateTask:
      String(localized: "New Template Task", bundle: .module)
    }
  }

  var editTitle: String {
    switch type {
    case .activity:
      String(localized: "Edit Activity", bundle: .module)
    case .activityTask:
      String(localized: "Edit Activity Task", bundle: .module)
    case .template:
      String(localized: "Edit Template", bundle: .module)
    case .templateTask:
      String(localized: "Edit Template Task", bundle: .module)
    }
  }
}

extension DayActivityForm {
  public func newTaskForm(newId: UUID) -> DayActivityForm? {
    switch type {
    case .activity(let showCompleted):
      return DayActivityForm(
        id: newId,
        parentId: id,
        type: .activityTask(showCompleted: showCompleted)
      )
    case .activityTask:
      return nil
    case .template:
      return DayActivityForm(
        id: newId,
        parentId: id,
        type: .templateTask
      )
    case .templateTask:
      return nil
    }
  }

  private init?(
    id: UUID,
    parentId: UUID,
    type: DayActivityFormType
  ) {
    self.init(
      id: id,
      ids: [.parentId: parentId],
      completed: false,
      name: .empty,
      tags: [],
      duration: .zero,
      overview: .empty,
      tasks: [],
      labels: [],
      type: type
    )
  }
}

extension DayActivityForm {
  public init(dayActivity: DayActivity, showCompleted: Bool) {
    self.id = dayActivity.id
    self.ids = [
      .dayId: dayActivity.dayId
    ]
    if let templateId = dayActivity.activity?.id {
      ids[.templateId] = templateId
    }
    self.completed = dayActivity.doneDate != nil
    self.icon = dayActivity.icon
    self.name = dayActivity.name
    self.tags = dayActivity.tags
    self.duration = dayActivity.duration
    self.reminderDate = dayActivity.reminderDate
    self.overview = dayActivity.overview ?? ""
    self.tasks = dayActivity.dayActivityTasks.map { dayActivityTask in
      DayActivityForm(dayActivityTask: dayActivityTask, showCompleted: showCompleted)
    }
    self.labels = dayActivity.labels
    self.frequency = nil
    self.type = .activity(showCompleted: showCompleted)
  }
}

extension DayActivity {
  public init?(form: DayActivityForm) {
    guard let dayId = form.ids[.dayId] else { return nil }
    @Dependency(\.date) var date
    self.init(
      id: form.id,
      dayId: dayId,
      activity: nil,
      name: form.name,
      icon: form.icon,
      doneDate: form.completed ? date.now : nil,
      duration: form.duration,
      overview: form.overview,
      isGeneratedAutomatically: false,
      tags: form.tags,
      labels: form.labels,
      dayActivityTasks: form.tasks.compactMap(DayActivityTask.init),
      reminderDate: form.reminderDate
    )
  }

  public mutating func update(by form: DayActivityForm) {
    @Dependency(\.date) var date
    self.name = form.name
    self.icon = form.icon
    if doneDate == nil && form.completed {
      doneDate = date.now
    } else if !form.completed {
      doneDate = nil
    }
    self.duration = form.duration
    self.overview = form.overview
    self.tags = form.tags
    self.labels = form.labels
    self.dayActivityTasks = form.tasks.compactMap(DayActivityTask.init)
    self.reminderDate = form.reminderDate
  }
}

extension DayActivityForm {
  public init(dayActivityTask: DayActivityTask, showCompleted: Bool) {
    self.id = dayActivityTask.id
    self.ids = [
      .parentId: dayActivityTask.dayActivityId
    ]
    if let templateId = dayActivityTask.activityTask?.id {
      ids[.templateId] = templateId
    }
    self.completed = dayActivityTask.doneDate != nil
    self.icon = dayActivityTask.icon
    self.name = dayActivityTask.name
    self.tags = []
    self.duration = dayActivityTask.duration
    self.reminderDate = dayActivityTask.reminderDate
    self.overview = dayActivityTask.overview ?? ""
    self.tasks = []
    self.labels = []
    self.frequency = nil
    self.type = .activityTask(showCompleted: showCompleted)
  }
}

extension DayActivityTask {
  public init?(form: DayActivityForm) {
    guard let parentId = form.ids[.parentId] else { return nil }
    @Dependency(\.date) var date
    self.init(
      id: form.id,
      dayActivityId: parentId,
      activityTask: nil,
      name: form.name,
      icon: form.icon,
      doneDate: form.completed ? date() : nil,
      duration: form.duration,
      overview: form.overview,
      reminderDate: form.reminderDate
    )
  }

  public mutating func update(by form: DayActivityForm) {
    @Dependency(\.date) var date
    name = form.name
    icon = form.icon
    if doneDate == nil && form.completed {
      doneDate = date.now
    } else if !form.completed {
      doneDate = nil
    }
    duration = form.duration
    overview = form.overview
    reminderDate = form.reminderDate
  }
}

extension DayActivityForm {
  public init(activity: Activity) {
    self.id = activity.id
    self.ids = [:]
    self.completed = false
    self.icon = activity.icon
    self.name = activity.name
    self.tags = activity.tags
    self.duration = activity.duration
    self.reminderDate = activity.reminderDate
    self.overview = activity.overview ?? ""
    self.tasks = activity.tasks.map(DayActivityForm.init)
    self.labels = activity.labels
    self.frequency = activity.frequency
    self.type = .template
  }
}

extension Activity {
  public init(form: DayActivityForm, startDate: Date) {
    self.init(
      id: form.id,
      name: form.name,
      icon: form.icon,
      tags: form.tags,
      frequency: form.frequency,
      defaultDuration: form.duration,
      startDate: startDate,
      labels: form.labels,
      tasks: form.tasks.compactMap(ActivityTask.init),
      defaultReminderDate: form.reminderDate
    )
  }

  public mutating func update(by form: DayActivityForm, startDate: Date) {
    @Dependency(\.date) var date
    self.name = form.name
    self.icon = form.icon
    self.tags = form.tags
    self.frequency = form.frequency
    self.defaultDuration = form.duration
    self.startDate = startDate
    self.labels = form.labels
    self.tasks = form.tasks.compactMap(ActivityTask.init)
    self.defaultReminderDate = form.reminderDate
  }
}

extension DayActivityForm {
  public init(activityTask: ActivityTask) {
    self.id = activityTask.id
    self.ids = [
      .parentId: activityTask.activityId
    ]
    self.completed = false
    self.icon = activityTask.icon
    self.name = activityTask.name
    self.tags = []
    self.duration = activityTask.defaultDuration ?? .zero
    self.reminderDate = activityTask.defaultReminderDate
    self.overview = ""
    self.tasks = []
    self.labels = []
    self.frequency = nil
    self.type = .templateTask
  }
}

extension ActivityTask {
  public init?(form: DayActivityForm) {
    guard let parentId = form.ids[.parentId] else { return nil }
    self.init(
      id: form.id,
      activityId: parentId,
      name: form.name,
      icon: form.icon,
      defaultDuration: form.duration,
      defaultReminderDate: form.reminderDate
    )
  }

  public mutating func update(by form: DayActivityForm) {
    self.name = form.name
    self.icon = form.icon
    self.defaultDuration = form.duration
    self.defaultReminderDate = form.reminderDate
  }
}

extension DayActivityForm {
  public var validated: Bool {
    requriedFields.allSatisfy { requriedField in
      switch requriedField {
      case .completed: true
      case .icon: icon != nil
      case .name: !name.isEmpty
      case .tags: !tags.isEmpty
      case .frequency: isFrequencyValid
      case .duration: duration > .zero
      case .reminder: reminderDate != nil
      case .overview: !overview.isEmpty
      case .tasks: !tasks.isEmpty
      case .labels: !labels.isEmpty
      }
    }
  }
}
