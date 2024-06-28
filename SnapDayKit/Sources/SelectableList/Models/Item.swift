import Foundation
import Models

public struct Item: Identifiable, Equatable {

  public enum LeftItem: Equatable {
    case icon(Icon?)
    case color(RGBColor)
    case none
  }

  public let id: String
  let name: String
  let leftItem: LeftItem

  public init(
    id: String,
    name: String,
    leftItem: LeftItem
  ) {
    self.id = id
    self.name = name
    self.leftItem = leftItem
  }
}
