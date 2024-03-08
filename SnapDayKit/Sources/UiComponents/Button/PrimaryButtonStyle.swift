import SwiftUI
import Resources

public struct PrimaryButtonStyle: ButtonStyle {

  // MARK: - Properties

  private let disabled: Bool

  // MARK: - Initialization

  public init(disabled: Bool = false) {
    self.disabled = disabled
  }

  // MARK: - ButtonStyle

  public func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Colors.pureWhite.swiftUIColor)
      .frame(height: 40.0)
      .maxWidth(alignment: .bottom)
      .background(
        backgroundColor
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
  }

  private var backgroundColor: Color {
    disabled
    ? Colors.fadedPurple.swiftUIColor
    : Colors.lavenderBliss.swiftUIColor
  }
}
