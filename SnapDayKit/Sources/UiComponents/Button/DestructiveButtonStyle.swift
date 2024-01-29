import SwiftUI
import Resources

public struct DestructiveButtonStyle: ButtonStyle {

  // MARK: - Initialization

  public init() { }

  // MARK: - ButtonStyle

  public func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 14.0))
      .foregroundStyle(Colors.crimson.swiftUIColor)
      .frame(height: 40.0)
      .maxWidth(alignment: .bottom)
  }
}
