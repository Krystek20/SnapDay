import Foundation

public struct Activity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var name: String
  public var image: Data?
  public var tags: [Tag]
  public var frequency: ActivityFrequency?
  public var defaultDuration: Int?
  public var isVisible: Bool
  public var startDate: Date?

  // MARK: - Initialization
  
  public init(
    id: UUID,
    name: String = "",
    image: Data? = nil,
    tags: [Tag] = [],
    frequency: ActivityFrequency? = nil,
    isDefaultDuration: Bool = false,
    defaultDuration: Int? = nil,
    isVisible: Bool = true,
    startDate: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.image = image
    self.tags = tags
    self.frequency = frequency
    self.defaultDuration = defaultDuration
    self.isVisible = isVisible
    self.startDate = startDate
  }
}

extension Activity {
  public var isRepeatable: Bool {
    frequency != nil
  }
}
