import Foundation

public struct Share: Identifiable, Equatable {

  // MARK: - Properties

  public var id: String { owner }
  public let owner: String
  public var sharedDayActivities: [SharedDayActivity]
  public var isCurrentUserOwner: Bool?
  public var participants: [Participant]

  // MARK: - Initialization

  public init(
    owner: String,
    sharedDayActivities: [SharedDayActivity],
    isCurrentUserOwner: Bool? = nil,
    participants: [Participant] = []
  ) {
    self.owner = owner
    self.sharedDayActivities = sharedDayActivities
    self.isCurrentUserOwner = isCurrentUserOwner
    self.participants = participants
  }
}
