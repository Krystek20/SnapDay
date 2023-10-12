import Foundation

public struct Activity: Identifiable, Equatable {

  // MARK: - Properties

  public let id: UUID
  public let name: String
  public let emoji: String?
  public let category: ActivityCategory
  public let state: ActivityState
  
  // MARK: - Initialization
  
  public init(
    id: UUID,
    name: String,
    emoji: String?,
    category: ActivityCategory,
    state: ActivityState
  ) {
    self.id = id
    self.name = name
    self.emoji = emoji
    self.category = category
    self.state = state
  }
}
