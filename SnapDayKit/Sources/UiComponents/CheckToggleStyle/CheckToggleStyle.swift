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
          .foregroundStyle(configuration.isOn ? Colors.lavenderBliss.swiftUIColor : Colors.slateHaze.swiftUIColor)
          .imageScale(.medium)
      }
    }
    .buttonStyle(.plain)
  }
}
