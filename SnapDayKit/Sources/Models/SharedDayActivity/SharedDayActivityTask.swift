import Foundation

public struct SharedDayActivityTask: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let sharedDayActivityId: UUID
  public var name: String
  public var nameLastUpdated: Date?
  public var doneDate: Date?
  public var doneDateLastUpdated: Date?
  public var doneByUserId: String?
  public var sharedBy: [SharedBy]
  public var removed: Bool

  // MARK: - Initialization

  public init(
    id: UUID,
    sharedDayActivityId: UUID,
    name: String,
    nameLastUpdated: Date?,
    doneDate: Date?,
    doneDateLastUpdated: Date?,
    doneByUserId: String?,
    sharedBy: [SharedBy],
    removed: Bool = false
  ) {
    self.id = id
    self.sharedDayActivityId = sharedDayActivityId
    self.name = name
    self.nameLastUpdated = nameLastUpdated
    self.doneDate = doneDate
    self.doneDateLastUpdated = doneDateLastUpdated
    self.doneByUserId = doneByUserId
    self.sharedBy = sharedBy
    self.removed = removed
  }
}
