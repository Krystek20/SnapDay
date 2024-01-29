import SwiftUI
import Resources

public extension View {
  var formBackgroundModifier: some View {
    modifier(FormBackgroundModifier())
  }
}

struct FormBackgroundModifier: ViewModifier {

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .padding(.all, 10.0)
      .background(
        Colors.pureWhite.swiftUIColor
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      )
  }
}
