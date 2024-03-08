import SwiftUI
import Resources

public struct SecondaryButtonStyle: ButtonStyle {

  // MARK: - Initialization

  public init() { }

  // MARK: - ButtonStyle

  public func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Color.slateHaze)
      .frame(height: 40.0)
      .maxWidth(alignment: .bottom)
      .background(
        Color.pureWhite
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
      .overlay {
        RoundedRectangle(cornerRadius: 10.0)
          .stroke(Color.slateHaze.opacity(0.2), lineWidth: 1.0)
      }
  }
}
