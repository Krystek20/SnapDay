import Foundation

public struct Activity: Identifiable, Equatable, Hashable, Decodable {

  // MARK: - Properties

  public let id: UUID
  public var name: String
  public var iconId: UUID?
  public var tags: [Tag]
  public var frequency: ActivityFrequency
  public var isFrequentEnabled: Bool
  public var defaultDuration: Int?
  public var dueDaysCount: Int?
  public var startDate: Date?
  public var labels: [ActivityLabel]
  public var tasks: [ActivityTask]
  public var defaultReminderDate: Date?
  public var important: Bool

  // MARK: - Initialization

  public init(
    id: UUID,
    name: String = "",
    iconId: UUID? = nil,
    tags: [Tag] = [],
    frequency: ActivityFrequency = .daily,
    isFrequentEnabled: Bool = false,
    defaultDuration: Int? = nil,
    dueDaysCount: Int? = nil,
    startDate: Date? = nil,
    labels: [ActivityLabel] = [],
    tasks: [ActivityTask] = [],
    defaultReminderDate: Date? = nil,
    important: Bool = false
  ) {
    self.id = id
    self.name = name
    self.iconId = iconId
    self.tags = tags
    self.frequency = frequency
    self.isFrequentEnabled = isFrequentEnabled
    self.defaultDuration = defaultDuration
    self.dueDaysCount = dueDaysCount
    self.startDate = startDate
    self.labels = labels
    self.tasks = tasks
    self.defaultReminderDate = defaultReminderDate
    self.important = important
  }
}
