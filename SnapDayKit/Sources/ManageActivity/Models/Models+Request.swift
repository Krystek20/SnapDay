import Foundation
import Models
import Dependencies
import AIModule
import Repositories

enum AIModuleError: LocalizedError {
  case fieldsNotFound
  case requiredFieldNotFound(fieldName: String)
  case changesNotFound

  var errorDescription: String? {
    switch self {
    case .fieldsNotFound:
      "Fields not found"
    case .requiredFieldNotFound(let fieldName):
      "Required field not found \(fieldName)"
    case .changesNotFound:
      "Changes not found"
    }
  }
}

extension ActivityFrequency {
  init?(action: [String: JSONValue]) {
    guard let type = action["type"]?.stringValue else {
      return nil
    }
    switch type {
    case "daily":
      self = .daily
    case "weekly":
      let days = action["days"]?.arrayValue?.compactMap(\.intValue) ?? []
      self = .weekly(days: days)
    case "biweekly":
      let days = action["days"]?.arrayValue?.compactMap(\.intValue) ?? []
      self = .biweekly(days: days, startWeek: .current)
    case "monthly":
      guard let monthly = action["monthly"]?.objectValue,
            let monthlyType = monthly["type"]?.stringValue else {
        return nil
      }
      switch monthlyType {
      case "specificDay":
        let days = action["days"]?.arrayValue?.compactMap(\.intValue) ?? []
        self = .monthly(monthlySchedule: .monthlySpecificDate(days))
      case "dayOfWeek":
        let dayOfWeekRules = monthly["rules"]?.arrayValue?
          .compactMap(\.objectValue)
          .compactMap { jsonObject -> WeekdayOrdinal? in
            let weekdays = jsonObject["days"]?.arrayValue?.compactMap(\.intValue) ?? []
            guard let type = jsonObject["type"]?.stringValue else { return nil }

            let weekdayOrdinalPosition: WeekdayOrdinal.Position? = switch type {
            case "first": .first
            case "second": .second
            case "third": .third
            case "fourth": .fourth
            case "penultimate": .secondToLastDay
            case "last": .last
            default: nil
            }

            guard let position = weekdayOrdinalPosition else { return nil }
            return WeekdayOrdinal(position: position, weekdays: weekdays)
          } ?? []
        self = .monthly(monthlySchedule: .weekdayOrdinal(dayOfWeekRules))
      case "firstDay":
        self = .monthly(monthlySchedule: .firstDay)
      case "secondDay":
        self = .monthly(monthlySchedule: .secondDay)
      case "middleOfMonth":
        self = .monthly(monthlySchedule: .midMonth)
      case "penultimateDay":
        self = .monthly(monthlySchedule: .secondToLastDay)
      case "lastDay":
        self = .monthly(monthlySchedule: .lastDay)
      default:
        return nil
      }
    default:
      return nil
    }
  }
}

extension Activity: Updateable {
  init(
    uuid: UUIDGenerator,
    action: ManageActivityAction,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let name = fields["name"]?.stringValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }

    var activityFrequency = ActivityFrequency.daily
    if let frequencyObject = fields["frequency"]?.objectValue,
       let frequency = ActivityFrequency(action: frequencyObject) {
      activityFrequency = frequency
    }

    let existingTags = try await tagRepository.loadTags([])
    let requestedNames = Set(fields["tagsIdentifiers"]?.arrayValue?.compactMap(\.stringValue) ?? [])
    let tags = existingTags.filter { requestedNames.contains($0.name) }

    var labels = [ActivityLabel]()
    let labelsNames = fields["labelsIdentifiers"]?.arrayValue?.compactMap(\.stringValue) ?? []
    for labelsName in labelsNames {
      let activityLabel = ActivityLabel(name: labelsName)
      try await activityLabelRepository.saveLabel(activityLabel)
      labels.append(activityLabel)
    }

    var iconIdentifier: UUID?
    if let iconParameters = fields["icon"]?.objectValue,
       let emoji = iconParameters["value"]?.stringValue,
       let data = emoji.emojiToImage(size: 140.0).pngData() {

      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconIdentifier = icon.id
    }

    let identifier = fields["identifier"]?.uuidValue ?? uuid()

    self.init(
      id: identifier,
      name: name,
      iconId: iconIdentifier,
      tags: tags,
      frequency: activityFrequency,
      isFrequentEnabled: fields["isFrequentEnabled"]?.boolValue ?? false,
      defaultDuration: fields["defaultDuration"]?.intValue,
      dueDaysCount: fields["dueDaysCount"]?.intValue,
      startDate: ISO8601DateFormatter.date(from: fields["startDate"]?.stringValue),
      labels: labels,
      tasks: [],
      defaultReminderDate: ISO8601DateFormatter.date(from: fields["defaultReminderDate"]?.stringValue, timeZone: .autoupdatingCurrent),
      important: fields["important"]?.boolValue ?? false
    )
  }

  mutating func update(
    with action: ManageActivityAction,
    uuid: UUIDGenerator,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    let changes = try extractChanges(from: action)
    updateField(changes["name"], field: &name, decode: { $0.stringValue })
    updateField(changes["iconId"], field: &iconId, decode: { $0.uuidValue })

    if let tagsChanges = changes["tagsIdentifiers"] {
      let existingTags = try await tagRepository.loadTags([])
      let requestedNames = Set(tagsChanges.arrayValue?.compactMap(\.stringValue) ?? [])
      tags = existingTags.filter { requestedNames.contains($0.name) }
    }

    if let frequencyObject = changes["frequency"]?.objectValue,
       let activityFrequency = ActivityFrequency(action: frequencyObject) {
      frequency = activityFrequency
    }

    if let iconParameters = changes["icon"]?.objectValue,
       let emoji = iconParameters["value"]?.stringValue,
       let data = emoji.emojiToImage(size: 140.0).pngData() {

      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconId = icon.id
    }

    updateField(changes["isFrequentEnabled"], field: &isFrequentEnabled, decode: { $0.boolValue })
    updateField(changes["defaultDuration"], field: &defaultDuration, decode: { $0.intValue })
    updateField(changes["dueDaysCount"], field: &dueDaysCount, decode: { $0.intValue })
    updateField(changes["startDate"], field: &startDate, decode: FieldDecoder.date)

    if let labelsChanges = changes["labelsIdentifiers"] {
      let existingLabels = try await activityLabelRepository.loadLabels(id, [])
      let requestedNames = Set(labelsChanges.arrayValue?.compactMap(\.stringValue) ?? [])
      labels = existingLabels.filter { requestedNames.contains($0.name) }
    }

    // TASKS
    updateField(changes["defaultReminderDate"], field: &defaultReminderDate, decode: FieldDecoder.date)
    updateField(changes["important"], field: &important, decode: { $0.boolValue })
  }
}

extension ActivityTask: Updateable {
  init(uuid: UUIDGenerator, action: ManageActivityAction) throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let name = fields["name"]?.stringValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }
    guard let activityId = fields["activityTemplateIdentifier"]?.uuidValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "activityTemplateIdentifier")
    }

    self.init(
      id: fields["identifier"]?.uuidValue ?? uuid(),
      activityId: activityId,
      name: name,
      defaultDuration: fields["defaultDuration"]?.intValue,
      defaultReminderDate: ISO8601DateFormatter.date(from: fields["defaultReminderDate"]?.stringValue, timeZone: .autoupdatingCurrent),
      defaultPosition: fields["defaultPosition"]?.intValue ?? .zero
    )
  }

  mutating func update(with action: ManageActivityAction) throws {
    let changes = try extractChanges(from: action)
    updateField(changes["name"], field: &name, decode: { $0.stringValue })
    updateField(changes["defaultDuration"], field: &defaultDuration, decode: { $0.intValue })
    updateField(changes["defaultReminderDate"], field: &defaultReminderDate, decode: FieldDecoder.date)
    updateField(changes["defaultPosition"], field: &defaultPosition, decode: { $0.intValue })
  }
}

extension DayActivity: Updateable {
  init(
    uuid: UUIDGenerator,
    action: ManageActivityAction,
    activity: Activity?,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository,
    calendar: Calendar
  ) async throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let iso8601Date = ISO8601DateFormatter.date(from: action.fields?["date"]?.stringValue) else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "date")
    }

    let name = fields["name"]?.stringValue ?? activity?.name
    guard let name else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }

    let existingTags = try await tagRepository.loadTags([])
    let requestedNames = Set(fields["tagsIdentifiers"]?.arrayValue?.compactMap(\.stringValue) ?? [])
    let tags = existingTags.filter { requestedNames.contains($0.name) }

    var labels = [ActivityLabel]()
    if let activityId = activity?.id {
      let existingLabels = try await activityLabelRepository.loadLabels(activityId, [])
      let requestedNames = Set(fields["labelsIdentifiers"]?.arrayValue?.compactMap(\.stringValue) ?? [])
      labels = existingLabels.filter { requestedNames.contains($0.name) }
    }

    var iconIdentifier: UUID?
    if let iconParameters = fields["icon"]?.objectValue,
       let emoji = iconParameters["value"]?.stringValue,
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
      id: fields["identifier"]?.uuidValue ?? uuid(),
      date: calendar.dayFormat(iso8601Date),
      activity: activity,
      name: name,
      iconId: iconIdentifier,
      dueDate: ISO8601DateFormatter.date(from: fields["dueDate"]?.stringValue),
      doneDate: ISO8601DateFormatter.date(from: fields["doneDate"]?.stringValue),
      duration: fields["duration"]?.intValue ?? .zero,
      overview: fields["overview"]?.stringValue,
      isGeneratedAutomatically: false,
      tags: tags,
      labels: labels,
      dayActivityTasks: [],
      reminderDate: ISO8601DateFormatter.date(from: fields["reminderDate"]?.stringValue, timeZone: .autoupdatingCurrent),
      important: fields["important"]?.boolValue ?? false,
      position: fields["position"]?.intValue ?? -1,
      share: nil
    )
  }

  mutating func update(
    with action: ManageActivityAction,
    uuid: UUIDGenerator,
    tagRepository: TagRepository,
    activityLabelRepository: ActivityLabelRepository,
    iconRepository: IconRepository
  ) async throws {
    let changes = try extractChanges(from: action)
    updateField(changes["date"], field: &date, decode: FieldDecoder.date)
    updateField(changes["name"], field: &name, decode: { $0.stringValue })
    updateField(changes["iconId"], field: &iconId, decode: { $0.uuidValue })
    updateField(changes["dueDate"], field: &dueDate, decode: FieldDecoder.date)
    updateField(changes["doneDate"], field: &doneDate, decode: FieldDecoder.date)
    updateField(changes["duration"], field: &duration, decode: { $0.intValue })
    updateField(changes["overview"], field: &overview, decode: { $0.stringValue })

    if let tagsChanges = changes["tagsIdentifiers"] {
      let existingTags = try await tagRepository.loadTags([])
      let requestedNames = Set(tagsChanges.arrayValue?.compactMap(\.stringValue) ?? [])
      tags = existingTags.filter { requestedNames.contains($0.name) }
    }

    if let labelsChanges = changes["labelsIdentifiers"], let activityId = activity?.id {
      let existingLabels = try await activityLabelRepository.loadLabels(activityId, [])
      let requestedNames = Set(labelsChanges.arrayValue?.compactMap(\.stringValue) ?? [])
      labels = existingLabels.filter { requestedNames.contains($0.name) }
    }

    if let iconParameters = changes["icon"]?.objectValue,
       let emoji = iconParameters["value"]?.stringValue,
       let data = emoji.emojiToImage(size: 140.0).pngData() {

      let icon = Icon(
        id: uuid(),
        data: data,
        lastUpdated: Date()
      )
      try await iconRepository.saveIcon(icon)
      iconId = icon.id
    }

    updateField(changes["reminderDate"], field: &reminderDate, decode: FieldDecoder.date)
    updateField(changes["important"], field: &important, decode: { $0.boolValue })
    updateField(changes["position"], field: &position, decode: { $0.intValue })
  }
}

extension DayActivityRequest {
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
      tags: dayActivity.tags.map(MarkerRequest.init),
      labels: dayActivity.labels.map(MarkerRequest.init),
      tasks: dayActivity.dayActivityTasks.map(DayActivityTaskRequest.init),
      reminderDate: dayActivity.reminderDate,
      important: dayActivity.important,
      position: dayActivity.position
    )
  }
}

extension DayActivityTask: Updateable {
  init(
    uuid: UUIDGenerator,
    action: ManageActivityAction
  ) throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let dayActivityId = fields["dayActivityId"]?.uuidValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "dayActivityId")
    }
    guard let name = fields["name"]?.stringValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }
    self.init(
      id: fields["identifier"]?.uuidValue ?? uuid(),
      dayActivityId: dayActivityId,
      activityTask: nil,
      name: name,
      doneDate: ISO8601DateFormatter.date(from: fields["doneDate"]?.stringValue),
      duration: fields["duration"]?.intValue ?? .zero,
      overview: fields["overview"]?.stringValue,
      reminderDate: ISO8601DateFormatter.date(from: fields["reminderDate"]?.stringValue, timeZone: .autoupdatingCurrent),
      position: fields["position"]?.intValue ?? -1
    )
  }

  mutating func update(with action: ManageActivityAction) throws {
    let changes = try extractChanges(from: action)
    updateField(changes["name"], field: &name, decode: { $0.stringValue })
    updateField(changes["doneDate"], field: &doneDate, decode: FieldDecoder.date)
    updateField(changes["duration"], field: &duration, decode: { $0.intValue })
    updateField(changes["overview"], field: &overview, decode: { $0.stringValue })
    updateField(changes["reminderDate"], field: &reminderDate, decode: FieldDecoder.date)
    updateField(changes["position"], field: &position, decode: { $0.intValue })
  }
}

extension DayActivityTaskRequest {
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

extension MarkerRequest {
  init(tag: Tag) {
    self.init(name: tag.name)
  }

  init(label: ActivityLabel) {
    self.init(name: label.name)
  }
}

extension Tag {
  init(action: ManageActivityAction) throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let name = fields["name"]?.stringValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }
    self.init(name: name)
  }
}

extension ActivityLabel {
  init(action: ManageActivityAction) throws {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let name = fields["name"]?.stringValue else {
      throw AIModuleError.requiredFieldNotFound(fieldName: "name")
    }
    self.init(name: name)
  }
}

extension ActivityTemplateRequest {
  init(activity: Activity) {
    self.init(
      identifier: activity.id,
      name: activity.name,
      iconIdentifier: activity.iconId,
      tags: activity.tags.map(MarkerRequest.init),
      isFrequentEnabled: activity.isFrequentEnabled,
      defaultDuration: activity.defaultDuration,
      dueDaysCount: activity.dueDaysCount,
      startDate: activity.startDate,
      labels: activity.labels.map(MarkerRequest.init),
      tasks: activity.tasks.map(ActivityTemplateTaskRequest.init),
      defaultReminderDate: activity.defaultReminderDate,
      important: activity.important
    )
  }
}

extension ActivityTemplateTaskRequest {
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

protocol Updateable { }

extension Updateable {
  func extractChanges(from action: ManageActivityAction) throws -> [String: JSONValue] {
    guard let fields = action.fields else {
      throw AIModuleError.fieldsNotFound
    }
    guard let changes = fields["changes"]?.objectValue else {
      throw AIModuleError.changesNotFound
    }

    return changes
  }

  func updateField<T>(
      _ value: JSONValue?,
      field: inout T,
      decode: (JSONValue) -> T?
  ) {
      guard let value, let decoded = decode(value) else { return }
      field = decoded
  }

  func updateField<T>(
      _ value: JSONValue?,
      field: inout T?,
      decode: (JSONValue) -> T?
  ) {
      guard let value else { return }
      field = decode(value)
  }
}

fileprivate struct FieldDecoder {
  static func date(_ value: JSONValue) -> Date? {
    guard let string = value.stringValue else { return nil }
    return ISO8601DateFormatter().date(from: string)
  }
}
