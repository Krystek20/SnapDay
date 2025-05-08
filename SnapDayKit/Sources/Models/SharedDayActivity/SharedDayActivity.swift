import Foundation

public struct SharedDayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var date: Date?
  public var dateLastUpdated: Date?
  public var name: String
  public var nameLastUpdated: Date?
  public var iconId: UUID
  public var dueDate: Date?
  public var dueDateLastUpdated: Date?
  public var tasks: [SharedDayActivityTask]
  public var sharedBy: [SharedBy]
  public var important: Bool
  public var importantLastUpdated: Date?
  public var lockTimestamp: Date?
  public var doneDate: Date?
  public var doneDateLastUpdated: Date?
  public var doneByUserId: String?

  // MARK: - Initialization

  public init(
    id: UUID,
    date: Date?,
    dateLastUpdated: Date?,
    name: String,
    nameLastUpdated: Date?,
    iconId: UUID,
    dueDate: Date? = nil,
    dueDateLastUpdated: Date?,
    tasks: [SharedDayActivityTask],
    sharedBy: [SharedBy],
    important: Bool,
    importantLastUpdated: Date?,
    lockTimestamp: Date?,
    doneDate: Date?,
    doneDateLastUpdated: Date?,
    doneByUserId: String?
  ) {
    self.id = id
    self.date = date
    self.dateLastUpdated = dateLastUpdated
    self.name = name
    self.nameLastUpdated = nameLastUpdated
    self.iconId = iconId
    self.dueDate = dueDate
    self.dueDateLastUpdated = dueDateLastUpdated
    self.tasks = tasks
    self.sharedBy = sharedBy
    self.important = important
    self.importantLastUpdated = importantLastUpdated
    self.lockTimestamp = lockTimestamp
    self.doneDate = doneDate
    self.doneDateLastUpdated = doneDateLastUpdated
    self.doneByUserId = doneByUserId
  }
}
