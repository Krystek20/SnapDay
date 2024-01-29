import SwiftUI
import Resources

public extension View {
  var titleTextStyle: some View {
    modifier(TitleTextModifier())
  }
}

struct TitleTextModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Fonts.Quicksand.bold.swiftUIFont(size: 28.0))
      .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
  }
}
