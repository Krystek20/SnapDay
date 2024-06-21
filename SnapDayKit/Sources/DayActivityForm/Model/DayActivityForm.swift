import Foundation
import Dependencies
import Models

public enum DayActivityFormId: String {
  case parentId
  case templateId
  case dayId
}

public struct DayActivityForm: Equatable, DurationProtocol, Identifiable {

  public var id: UUID
  public var ids: [DayActivityFormId: UUID]
  public var completed: Bool
  public var icon: Icon?
  public var name: String
  public var tags: [Tag]
  public var duration: Int
  public var reminderDate: Date?
  public var overview: String
  public var tasks: [DayActivityForm]
  public var labels: [ActivityLabel]
  public var frequency: ActivityFrequency?

  public var fields: [DayActivityField]
  public var requriedFields: [DayActivityField]

  let newTitle: String
  let editTitle: String
}

extension DayActivityForm {
  public init(dayActivity: DayActivity) {
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
    self.tasks = dayActivity.dayActivityTasks.map(DayActivityForm.init)
    self.labels = dayActivity.labels
    self.frequency = nil
    self.fields = [
      .completed,
      .icon,
      .name,
      .tags,
      .duration,
      .reminder,
      .overview,
      dayActivity.activity != nil ? .labels : nil,
      .tasks
    ].compactMap { $0 }
    self.requriedFields = [.name]
    self.newTitle = String(localized: "New Activity", bundle: .module)
    self.editTitle = String(localized: "Edit Activity", bundle: .module)
  }

  public init(dayActivityTask: DayActivityTask) {
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
    self.fields = [
      .completed,
      .icon,
      .name,
      .duration,
      .reminder,
      .overview
    ]
      .compactMap { $0 }
    self.requriedFields = [.name]
    self.newTitle = String(localized: "New Activity Task", bundle: .module)
    self.editTitle = String(localized: "Edit Activity Task", bundle: .module)
  }

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
    self.frequency = nil
    self.fields = [
      .icon,
      .name,
      .tags,
      .duration,
      .reminder,
      .overview,
      .tasks,
      .labels,
      .frequency
    ]
    self.requriedFields = [.name]
    self.newTitle = String(localized: "New Activity Template", bundle: .module)
    self.editTitle = String(localized: "Edit Activity Template", bundle: .module)
  }

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
    self.fields = [
      .icon,
      .name,
      .duration,
      .reminder
    ]
    self.requriedFields = [.name]
    self.newTitle = String(localized: "New Template Activity Task", bundle: .module)
    self.editTitle = String(localized: "Edit Template Activity Task", bundle: .module)
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
    self.dayActivityTasks = form.tasks.compactMap { taskForm in
      guard var dayActivityTask = dayActivityTasks.first(where: { $0.id == taskForm.id }) else {
        return DayActivityTask(form: taskForm)
      }
      dayActivityTask.update(by: taskForm)
      return dayActivityTask
    }
    self.reminderDate = form.reminderDate
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
  public var validated: Bool {
    requriedFields.allSatisfy { requriedField in
      switch requriedField {
      case .completed: true
      case .icon: icon != nil
      case .name: !name.isEmpty
      case .tags: !tags.isEmpty
      case .duration: duration > .zero
      case .reminder: reminderDate != nil
      case .overview: !overview.isEmpty
      case .tasks: !tasks.isEmpty
      case .labels: !labels.isEmpty
      case .frequency: frequency != nil
      }
    }
  }
}
