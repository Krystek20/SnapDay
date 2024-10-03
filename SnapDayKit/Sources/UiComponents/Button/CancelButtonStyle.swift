import SwiftUI
import Resources

public struct CancelButtonStyle: ButtonStyle {

  // MARK: - Initialization

  public init() { }

  // MARK: - ButtonStyle

  public func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Color.sectionText)
      .frame(height: 40.0)
      .maxWidth(alignment: .bottom)
  }
}
