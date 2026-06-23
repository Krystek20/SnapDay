import Foundation
import Models
import Dependencies
import AIModule
import Repositories

extension ActivityFrequency {
  init?(frequency: Frequency) {
    switch frequency {
    case .daily:
      self = .daily
    case .weekly(let days):
      self = .weekly(days: days.map(\.rawValue))
    case .biweekly(let days):
      self = .biweekly(days: days.map(\.rawValue), startWeek: .current)
    case .monthly(let frequencyMonthly):
      switch frequencyMonthly {
      case .fixedPosition(let fixed):
        switch fixed {
        case .firstDay:
          self = .monthly(monthlySchedule: .firstDay)
        case .secondDay:
          self = .monthly(monthlySchedule: .secondDay)
        case .middleOfMonth:
          self = .monthly(monthlySchedule: .midMonth)
        case .penultimateDay:
          self = .monthly(monthlySchedule: .secondToLastDay)
        case .lastDay:
          self = .monthly(monthlySchedule: .lastDay)
        }
      case .specificDay(let days):
        self = .monthly(monthlySchedule: .monthlySpecificDate(days.map(\.rawValue)))
      case .dayOfWeek(let rules):
        let weekdayOrdinals = rules.map { rule in
          switch rule.type {
          case .first:
            WeekdayOrdinal(position: .first, weekdays: rule.days.map(\.rawValue))
          case .second:
            WeekdayOrdinal(position: .second, weekdays: rule.days.map(\.rawValue))
          case .third:
            WeekdayOrdinal(position: .third, weekdays: rule.days.map(\.rawValue))
          case .fourth:
            WeekdayOrdinal(position: .fourth, weekdays: rule.days.map(\.rawValue))
          case .penultimate:
            WeekdayOrdinal(position: .secondToLastDay, weekdays: rule.days.map(\.rawValue))
          case .last:
            WeekdayOrdinal(position: .last, weekdays: rule.days.map(\.rawValue))
          }
        }
        self = .monthly(monthlySchedule: .weekdayOrdinal(weekdayOrdinals))
      }
    }
  }
}

extension Activity {
  init(
    uuid: UUIDGenerator,
    payload: CreateActivityTemplate,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    var activityFrequency = ActivityFrequency.daily
    if let frequencyObject = payload.frequency,
       let frequency = ActivityFrequency(frequency: frequencyObject) {
      activityFrequency = frequency
    }

    let existingTags = try await tagRepository.loadTags([])
    let requestedTags = Set(payload.tags)
    let tags = requestedTags.map { name in
      existingTags.first(where: { $0.name == name }) ?? Tag(name: name)
    }

    var labels = [ActivityLabel]()
    for labelsName in payload.labels {
      let activityLabel = ActivityLabel(name: labelsName)
      try await activityLabelRepository.saveLabel(activityLabel)
      labels.append(activityLabel)
    }

    var iconIdentifier: UUID?
    if let emoji = payload.icon,
       let data = emoji.emojiToImage(size: 140.0).pngData() {
      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconIdentifier = icon.id
    }

    self.init(
      id: uuid(),
      name: payload.name,
      iconId: iconIdentifier,
      tags: tags,
      frequency: activityFrequency,
      isFrequentEnabled: payload.isFrequentEnabled,
      defaultDuration: payload.defaultDuration,
      dueDaysCount: payload.dueDaysCount,
      startDate: payload.startDate,
      labels: labels,
      tasks: [],
      defaultReminderDate: payload.defaultReminderDate,
      important: payload.important
    )
  }

  mutating func update(
    with payload: UpdateActivityTemplate,
    uuid: UUIDGenerator,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    if let emoji = payload.icon,
       let data = emoji.emojiToImage(size: 140.0).pngData() {
      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconId = icon.id
    }

    let existingTags = try await tagRepository.loadTags([])
    tags = Set(payload.tags).map { name in
      existingTags.first(where: { $0.name == name }) ?? Tag(name: name)
    }

    let existingLabels = try await activityLabelRepository.loadLabels(id, [])
    labels = Set(payload.labels).map { name in
      existingLabels.first(where: { $0.name == name }) ?? ActivityLabel(name: name)
    }

    if let frequencyObject = payload.frequency,
       let activityFrequency = ActivityFrequency(frequency: frequencyObject) {
      frequency = activityFrequency
    }

    name = payload.name
    isFrequentEnabled = payload.isFrequentEnabled ?? false
    defaultDuration = payload.defaultDuration
    dueDaysCount = payload.dueDaysCount
    startDate = payload.startDate
    defaultReminderDate = payload.defaultReminderDate
    important = payload.important ?? false
  }
}

extension ActivityTask {
  init(
    uuid: UUIDGenerator,
    activityId: UUID,
    payload: CreateActivityTemplateTask
  ) throws {
    self.init(
      id: uuid(),
      activityId: activityId,
      name: payload.name,
      defaultDuration: payload.defaultDuration,
      defaultReminderDate: payload.defaultReminderDate,
      defaultPosition: payload.defaultPosition ?? -1
    )
  }

  mutating func update(with payload: UpdateActivityTemplateTask) throws {
    name = payload.name
    defaultDuration = payload.defaultDuration
    defaultReminderDate = payload.defaultReminderDate
    defaultPosition = payload.defaultPosition ?? -1
  }
}

extension DayActivity {
  init(
    uuid: UUIDGenerator,
    payload: CreateDayActivity,
    tagRepository: TagRepository,
    iconRepository: IconRepository,
    calendar: Calendar
  ) async throws {
    let existingTags = try await tagRepository.loadTags([])
    let tags = Set(payload.tags).map { name in
      existingTags.first(where: { $0.name == name }) ?? Tag(name: name)
    }

    var iconIdentifier: UUID?
    if let emoji = payload.icon,
       let data = emoji.emojiToImage(size: 140.0).pngData() {
      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconIdentifier = icon.id
    }

    self.init(
      id: uuid(),
      date: calendar.dayFormat(payload.date),
      activity: nil,
      name: payload.name,
      iconId: iconIdentifier,
      dueDate: payload.dueDate,
      doneDate: payload.doneDate,
      duration: payload.duration ?? .zero,
      overview: payload.overview,
      isGeneratedAutomatically: false,
      tags: tags,
      labels: [],
      dayActivityTasks: [],
      reminderDate: payload.reminderDate,
      important: payload.important ?? false,
      position: payload.position ?? -1,
      share: nil
    )
  }

  static func create(
    uuid: UUIDGenerator,
    activity: Activity,
    payload: CreateDayActivity,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository,
    calendar: Calendar
  ) async throws -> DayActivity {
    var dayActivity = DayActivity.create(
      from: activity,
      uuid: uuid,
      calendar: { calendar },
      date: payload.date,
      createdByUser: false
    )

    dayActivity.name = payload.name
    dayActivity.overview = payload.overview
    dayActivity.date = payload.date
    dayActivity.doneDate = payload.doneDate
    dayActivity.dueDate = payload.dueDate
    dayActivity.reminderDate = payload.reminderDate
    dayActivity.duration = payload.duration ?? .zero
    dayActivity.position = payload.position ?? -1
    dayActivity.important = payload.important ?? false

    let existingTags = try await tagRepository.loadTags([])
    dayActivity.tags = Set(payload.tags).map { name in
      existingTags.first(where: { $0.name == name }) ?? Tag(name: name)
    }

    let existingLabels = try await activityLabelRepository.loadLabels(activity.id, [])
    dayActivity.labels = Set(payload.labels).map { name in
      existingLabels.first(where: { $0.name == name }) ?? ActivityLabel(name: name)
    }

    if let emoji = payload.icon,
       let data = emoji.emojiToImage(size: 140.0).pngData() {
      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      dayActivity.iconId = icon.id
    }

    return dayActivity
  }

  mutating func update(
    with payload: UpdateDayActivity,
    uuid: UUIDGenerator,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    name = payload.name
    overview = payload.overview
    date = payload.date
    doneDate = payload.doneDate
    dueDate = payload.dueDate
    reminderDate = payload.reminderDate
    duration = payload.duration ?? .zero
    position = payload.position ?? -1
    important = payload.important ?? false

    let existingTags = try await tagRepository.loadTags([])
    tags = Set(payload.tags).map { name in
      existingTags.first(where: { $0.name == name }) ?? Tag(name: name)
    }

    if let activityId = activity?.id {
      let existingLabels = try await activityLabelRepository.loadLabels(activityId, [])
      let requestedNames = Set(payload.labels)
      labels = requestedNames.map { name in
        existingLabels.first(where: { $0.name == name }) ?? ActivityLabel(name: name)
      }
    }

    if let emoji = payload.icon,
       let data = emoji.emojiToImage(size: 140.0).pngData() {
      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconId = icon.id
    } else {
      iconId = nil
    }
  }
}

extension DayActivityResponse {
  init(dayActivity: DayActivity) {
    self.init(
      identifier: dayActivity.id,
      date: dayActivity.date,
      templateIdentifier: dayActivity.activity?.id,
      name: dayActivity.name,
      iconIdentifier: dayActivity.iconId,
      dueDate: dayActivity.dueDate,
      doneDate: dayActivity.doneDate,
      duration: dayActivity.duration,
      overview: dayActivity.overview,
      tags: dayActivity.tags.map(MarkerResponse.init),
      labels: dayActivity.labels.map(MarkerResponse.init),
      tasks: dayActivity.dayActivityTasks.map(DayActivityTaskResponse.init),
      reminderDate: dayActivity.reminderDate,
      important: dayActivity.important,
      position: dayActivity.position
    )
  }
}

extension DayActivityTask {
  init(
    uuid: UUIDGenerator,
    dayActivityId: UUID,
    payload: CreateDayActivityTask,
  ) throws {
    self.init(
      id: uuid(),
      dayActivityId: dayActivityId,
      activityTask: nil,
      name: payload.name,
      doneDate: payload.doneDate,
      duration: payload.duration ?? .zero,
      overview: payload.overview,
      reminderDate: payload.reminderDate,
      position: payload.position ?? -1
    )
  }

  mutating func update(with payload: UpdateDayActivityTask) throws {
    name = payload.name
    doneDate = payload.doneDate
    duration = payload.duration ?? .zero
    overview = payload.overview
    reminderDate = payload.reminderDate
    position = payload.position ?? -1
  }
}

extension DayActivityTaskResponse {
  init(task: DayActivityTask) {
    self.init(
      identifier: task.id,
      dayActivityId: task.dayActivityId,
      activityTemplateIdentifier: task.activityTask?.activityId,
      name: task.name,
      doneDate: task.doneDate,
      duration: task.duration,
      overview: task.overview,
      reminderDate: task.reminderDate,
      position: task.position
    )
  }
}

extension MarkerResponse {
  init(tag: Tag) {
    self.init(name: tag.name)
  }

  init(label: ActivityLabel) {
    self.init(name: label.name)
  }
}

extension ActivityTemplateResponse {
  init(activity: Activity) {
    self.init(
      identifier: activity.id,
      name: activity.name,
      iconIdentifier: activity.iconId,
      tags: activity.tags.map(MarkerResponse.init),
      isFrequentEnabled: activity.isFrequentEnabled,
      defaultDuration: activity.defaultDuration,
      dueDaysCount: activity.dueDaysCount,
      startDate: activity.startDate,
      labels: activity.labels.map(MarkerResponse.init),
      tasks: activity.tasks.map(ActivityTemplateTaskResponse.init),
      defaultReminderDate: activity.defaultReminderDate,
      important: activity.important
    )
  }
}

extension ActivityTemplateTaskResponse {
  init(activityTask: ActivityTask) {
    self.init(
      identifier: activityTask.id,
      activityTemplateId: activityTask.activityId,
      name: activityTask.name,
      defaultDuration: activityTask.defaultDuration,
      defaultReminderDate: activityTask.defaultReminderDate,
      defaultPosition: activityTask.defaultPosition
    )
  }
}
