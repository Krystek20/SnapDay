#if DEBUG
import ComposableArchitecture
import Foundation
import SwiftUI

private let newPlanPreviewDate = Calendar(identifier: .gregorian).date(
  from: DateComponents(year: 2026, month: 6, day: 14)
)!

#Preview("New Plan") {
  NavigationStack {
    NewPlanView(
      store: Store(
        initialState: NewPlanFeature.State(
          name: "Learn Spanish",
          startDate: newPlanPreviewDate
        ),
        reducer: {
          NewPlanFeature()
        }
      )
    )
  }
}

#Preview("New Plan - dark") {
  NavigationStack {
    NewPlanView(
      store: Store(
        initialState: NewPlanFeature.State(
          name: "Learn Spanish",
          startDate: newPlanPreviewDate
        ),
        reducer: {
          NewPlanFeature()
        }
      )
    )
  }
  .preferredColorScheme(.dark)
}
#endif
