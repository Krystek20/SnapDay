import Foundation

public struct Icon: Identifiable, Equatable, Hashable, Decodable {

  // MARK: - Properties

  public let id: UUID
  public var data: Data?

  // MARK: - Initialization

  public init(
    id: UUID,
    data: Data? = nil
  ) {
    self.id = id
    self.data = data
  }
}
