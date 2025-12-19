import SwiftUI
import Resources

public struct PrimaryButtonStyle: ButtonStyle {

  // MARK: - Properties

  public enum Height: Double {
    case small = 30.0
    case standard = 40.0
  }

  @Environment(\.isEnabled) var isEnabled

  private let height: Height

  // MARK: - Initialization

  public init(height: Height = .standard) {
    self.height = height
  }

  // MARK: - ButtonStyle

  public func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Color.pureWhite)
      .frame(height: height.rawValue)
      .maxWidth(alignment: .bottom)
      .background(
        Color.actionBlue
          .opacity(configuration.isPressed ? 0.8 : (isEnabled ? 1.0 : 0.3))
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}
