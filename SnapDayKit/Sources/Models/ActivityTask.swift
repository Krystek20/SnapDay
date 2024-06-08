import Foundation

public struct ActivityTask: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var name: String
  public var icon: Icon?
  public var defaultDuration: Int?
  public var defaultReminderDate: Date?

  // MARK: - Initialization

  public init(
    id: UUID,
    name: String = "",
    icon: Icon? = nil,
    defaultDuration: Int? = nil,
    defaultReminderDate: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.defaultDuration = defaultDuration
    self.defaultReminderDate = defaultReminderDate
  }
}
