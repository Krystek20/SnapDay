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
      .font(.system(size: 28.0, weight: .bold))
      .foregroundStyle(Color.standardText)
  }
}
