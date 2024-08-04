import SwiftUI
import Resources

public struct CheckToggleStyle: ToggleStyle {

  private let showLabel: Bool

  // MARK: - Initialization

  public init(showLabel: Bool = true) {
    self.showLabel = showLabel
  }

  // MARK: - ToggleStyle

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      HStack {
        if showLabel {
          configuration.label
          Spacer()
        }
        Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(configuration.isOn ? Color.actionBlue : Color.sectionText)
          .imageScale(.medium)
      }
    }
    .buttonStyle(.plain)
  }
}
