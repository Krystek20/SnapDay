#if DEBUG
import ComposableArchitecture
import SwiftUI

#Preview("No selection") {
  OnboardingView(
    store: Store(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }
  )
}

#Preview("Goal selected") {
  OnboardingView(
    store: Store(initialState: OnboardingFeature.State(selectedGoal: .readMore)) {
      OnboardingFeature()
    }
  )
}
#endif
