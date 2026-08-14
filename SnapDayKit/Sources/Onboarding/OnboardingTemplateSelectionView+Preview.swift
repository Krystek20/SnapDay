#if DEBUG
import ComposableArchitecture
import SwiftUI

#Preview("Reading templates") {
  NavigationStack {
    OnboardingTemplateSelectionView(
      store: Store(
        initialState: OnboardingTemplateSelectionFeature.State(category: .reading)
      ) {
        OnboardingTemplateSelectionFeature()
      }
    )
  }
}

#Preview("Movement templates") {
  NavigationStack {
    OnboardingTemplateSelectionView(
      store: Store(
        initialState: OnboardingTemplateSelectionFeature.State(category: .movement)
      ) {
        OnboardingTemplateSelectionFeature()
      }
    )
  }
}
#endif
