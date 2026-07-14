#if DEBUG
import ComposableArchitecture
import SwiftUI

#Preview("Plans - active") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}

#Preview("Plans - empty") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(selectedSection: .active, activePlans: []),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}

#Preview("Plans - history") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(selectedSection: .history),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}
#endif
