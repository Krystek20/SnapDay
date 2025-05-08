import Foundation
import Common

public struct Icon: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var data: Data?
  public var lastUpdated: Date?

  // MARK: - Initialization

  public init(
    id: UUID,
    data: Data? = nil,
    lastUpdated: Date?
  ) {
    self.id = id
    self.data = data
    self.lastUpdated = lastUpdated
  }
}
