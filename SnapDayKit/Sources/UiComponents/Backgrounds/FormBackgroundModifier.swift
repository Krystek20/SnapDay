import SwiftUI
import Resources
import WidgetKit

public extension View {
  func formBackgroundModifier(
    color: Color = .formBackground,
    padding: EdgeInsets = EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
  ) -> some View {
    modifier(FormBackgroundModifier(color: color, padding: padding))
  }
}

struct FormBackgroundModifier: ViewModifier {

  let color: Color
  let padding: EdgeInsets

  @Environment(\.widgetRenderingMode) var widgetRenderingMode

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    switch widgetRenderingMode {
    case .fullColor, .vibrant:
      content
        .padding(padding)
        .background(
          color
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
        )
    case .accented:
      content
        .padding(padding)
    default:
      content
        .padding(padding)
        .background(
          color
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
        )
    }
  }
}
