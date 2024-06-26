import Foundation

public struct Activity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var name: String
  public var icon: Icon?
  public var tags: [Tag]
  public var frequency: ActivityFrequency?
  public var defaultDuration: Int?
  public var startDate: Date?
  public var labels: [ActivityLabel]
  public var tasks: [ActivityTask]
  public var defaultReminderDate: Date?

  // MARK: - Initialization
  
  public init(
    id: UUID,
    name: String = "",
    icon: Icon? = nil,
    tags: [Tag] = [],
    frequency: ActivityFrequency? = nil,
    defaultDuration: Int? = nil,
    startDate: Date? = nil,
    labels: [ActivityLabel] = [],
    tasks: [ActivityTask] = [],
    defaultReminderDate: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.tags = tags
    self.frequency = frequency
    self.defaultDuration = defaultDuration
    self.startDate = startDate
    self.labels = labels
    self.tasks = tasks
    self.defaultReminderDate = defaultReminderDate
  }
}
