import SwiftUI
import Resources

public extension View {
  func formBackgroundModifier(color: Color = Colors.pureWhite.swiftUIColor) -> some View {
    modifier(FormBackgroundModifier(color: color))
  }
}

struct FormBackgroundModifier: ViewModifier {

  let color: Color

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .padding(.all, 10.0)
      .background(
        color
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
  }
}
