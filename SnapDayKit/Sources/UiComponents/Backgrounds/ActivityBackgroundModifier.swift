import SwiftUI
import Resources

public extension View {
  var background: some View {
    modifier(BackgroundModifier(backgroundColor: .background))
  }

  var backgroundSoft: some View {
    modifier(BackgroundModifier(backgroundColor: .backgroundSoft))
  }
}

private struct BackgroundModifier: ViewModifier {

  let backgroundColor: Color

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .background(
        backgroundColor
          .ignoresSafeArea()
      )
  }
}
