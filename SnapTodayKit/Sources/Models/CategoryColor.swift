import SwiftUI

public enum CategoryColor: Equatable {
  case blue
  case red
  case orange
  case yellow
}

extension CategoryColor: Identifiable {
  public var id: String { String(describing: self) }
}

extension CategoryColor {
  public var color: Color {
    switch self {
    case .blue:
      return .blue
    case .red:
      return .red
    case .orange:
      return .orange
    case .yellow:
      return .yellow
    }
  }
}
