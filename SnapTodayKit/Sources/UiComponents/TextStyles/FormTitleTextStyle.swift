import SwiftUI
import Resources

public extension View {
  var formTitleTextStyle: some View {
    modifier(FormTitleTextStyle())
  }
}

struct FormTitleTextStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 14.0))
      .foregroundStyle(Colors.slateHaze.swiftUIColor)
  }
}
