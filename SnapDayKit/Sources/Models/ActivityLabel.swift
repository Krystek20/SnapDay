import Foundation

public struct ActivityLabel: Identifiable, Equatable, Hashable, Decodable {

  // MARK: - Properties

  public var id: String { name }
  public var name: String
  public var rgbColor: RGBColor

  // MARK: - Initialization

  public init(name: String, color: RGBColor = .random) {
    self.name = name
    self.rgbColor = color
  }
}
