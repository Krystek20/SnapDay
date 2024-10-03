import SwiftUI

struct OnboardingViewModifier: ViewModifier {

  let tag: OnboardingFeature.Tab

  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 20.0)
      .maxFrame(alignment: .center)
      .contentShape(Rectangle())
      .tag(tag)
      .gesture(DragGesture())
  }
}
