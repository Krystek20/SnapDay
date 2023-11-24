import SwiftUI
import ComposableArchitecture
import Application
import Dashboard
import HistoryList
import Details
import ActivityForm
import TagForm
import IconPicker
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
      initialState: DashboardFeature.State(userName: "John"),
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

#Preview("IconPickerView") {
  IconPickerView(
    store: Store(
      initialState: IconPickerFeature.State(),
      reducer: { IconPickerFeature() }
    )
  )
}

#Preview("HistoryListView") {
  HistoryListView(
    store: Store(
      initialState: HistoryListFeature.State(),
      reducer: { HistoryListFeature() }
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
