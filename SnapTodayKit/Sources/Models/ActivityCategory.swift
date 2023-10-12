import Foundation

public struct ActivityCategory: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let name: String
  public let emoji: String?
  public let color: CategoryColor

  // MARK: - Initialization

  public init(id: UUID, name: String, emoji: String?, color: CategoryColor) {
    self.id = id
    self.name = name
    self.emoji = emoji
    self.color = color
  }
}
