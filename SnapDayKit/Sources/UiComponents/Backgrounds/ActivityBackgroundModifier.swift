import SwiftUI
import Resources

public extension View {
  var activityBackground: some View {
    modifier(ActivityBackgroundModifier())
  }
}

struct ActivityBackgroundModifier: ViewModifier {

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .background(
        Color.grayLight
          .ignoresSafeArea()
      )
  }
}
