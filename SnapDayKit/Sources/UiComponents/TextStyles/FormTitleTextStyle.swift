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
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Color.slateHaze)
  }
}
