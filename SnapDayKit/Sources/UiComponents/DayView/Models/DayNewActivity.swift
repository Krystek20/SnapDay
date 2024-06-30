import Foundation

public struct DayNewActivity: Equatable {
  public var name: String
  public var isFormVisible: Bool

  public init(name: String, isFormVisible: Bool) {
    self.name = name
    self.isFormVisible = isFormVisible
  }
}
