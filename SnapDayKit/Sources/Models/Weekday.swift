import Foundation

public struct Weekday: Identifiable {
  public var id: String { name }
  public let name: String
  public let index: Int

  public init(name: String, index: Int) {
    self.name = name
    self.index = index
  }
}
