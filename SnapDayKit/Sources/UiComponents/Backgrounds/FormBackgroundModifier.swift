import SwiftUI
import Resources

public extension View {
  func formBackgroundModifier(
    color: Color = Colors.pureWhite.swiftUIColor,
    padding: EdgeInsets = EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
  ) -> some View {
    modifier(FormBackgroundModifier(color: color, padding: padding))
  }
}

struct FormBackgroundModifier: ViewModifier {

  let color: Color
  let padding: EdgeInsets

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(
        color
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
  }
}
