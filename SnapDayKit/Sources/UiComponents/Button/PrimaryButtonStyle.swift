import SwiftUI
import Resources

public struct PrimaryButtonStyle: ButtonStyle {

  // MARK: - Properties

  public enum Height: Double {
    case small = 30.0
    case standard = 40.0
  }

  private let disabled: Bool
  private let height: Height

  // MARK: - Initialization

  public init(
    disabled: Bool = false,
    height: Height = .standard
  ) {
    self.disabled = disabled
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
        Color.actionBlue.opacity(disabled ? 0.3 : 1.0)
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
  }
}
