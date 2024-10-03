import SwiftUI
import ComposableArchitecture
import Onboarding

#Preview("OnboardingView") {
  OnboardingView(
    store: Store(
      initialState: OnboardingFeature.State(),
      reducer: { OnboardingFeature() }
    )
  )
}
