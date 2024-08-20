import SwiftUI

public struct RGBColor: Equatable, Hashable, Identifiable, Decodable {

  // MARK: - Properties

  public var id: String {
    String(red) + String(green) + String(blue) + String(alpha)
  }
  public let red: Double
  public let green: Double
  public let blue: Double
  public let alpha: Double

  static let white = RGBColor(red: .zero, green: .zero, blue: .zero, alpha: 1.0)
  public static var random: RGBColor {
    RGBColor(
      red: Double.random(in: 0...255 / 255.0),
      green: Double.random(in: 0...255 / 255.0),
      blue: Double.random(in: 0...255 / 255.0),
      alpha: 1.0
    )
  }

  // MARK: - Initialization

  public init(red: Double, green: Double, blue: Double, alpha: Double) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}

public extension RGBColor {
  func isLight(threshold: Double = 0.5) -> Bool {
    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    return luminance > threshold
  }
}

public extension Color {
  var rgbColor: RGBColor {
    var red: CGFloat = .zero
    var green: CGFloat = .zero
    var blue: CGFloat = .zero
    var alpha: CGFloat = .zero
    guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return .white }
    return RGBColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}

public extension RGBColor {
  var color: Color {
    Color(red: red, green: green, blue: blue).opacity(alpha)
  }
}
