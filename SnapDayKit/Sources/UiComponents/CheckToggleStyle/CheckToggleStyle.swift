import SwiftUI
import Resources

public struct CheckToggleStyle: ToggleStyle {

  // MARK: - Initialization

  public init() { }

  // MARK: - ToggleStyle

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      HStack {
        configuration.label
        Spacer()
        Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(configuration.isOn ? Color.actionBlue : Color.sectionText)
          .imageScale(.medium)
      }
    }
    .buttonStyle(.plain)
  }
}
