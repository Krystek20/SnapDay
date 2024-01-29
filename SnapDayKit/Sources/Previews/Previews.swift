import SwiftUI
import ComposableArchitecture
import Application
import Dashboard
import PlanDetails
import Details
import ActivityForm
import TagForm
import EmojiPicker
import Models

#Preview("ApplicationView") {
  ApplicationView(
    store: Store(
      initialState: ApplicationFeature.State(),
      reducer: { ApplicationFeature() }
    )
  )
}

#Preview("DashboardView") {
  DashboardView(
    store: Store(
      initialState: DashboardFeature.State(),
      reducer: { DashboardFeature() }
    )
  )
}

#Preview("ActivityFormView") {
  ActivityFormView(
    store: Store(
      initialState: ActivityFormFeature.State(activity: Activity(id: UUID())),
      reducer: { ActivityFormFeature() }
    )
  )
}

#Preview("TagFormView") {
  TagFormView(
    store: Store(
      initialState: TagFormFeature.State(tag: Tag(name: "")),
      reducer: { TagFormFeature() }
    )
  )
}

#Preview("EmojiPickerView") {
  EmojiPickerView(
    store: Store(
      initialState: EmojiPickerFeature.State(),
      reducer: { EmojiPickerFeature() }
    )
  )
}

#Preview("PlanDetailsView") {
  PlanDetailsView(
    store: Store(
      initialState: PlanDetailsFeature.State(
        plan: Plan(
          id: UUID(),
          days: [],
          name: "",
          type: .daily,
          dateRange: Date()...Date()
        )
      ),
      reducer: { PlanDetailsFeature() }
    )
  )
}

#Preview("DetailsView") {
  DetailsView(
    store: Store(
      initialState: DetailsFeature.State(),
      reducer: { DetailsFeature() }
    )
  )
}
