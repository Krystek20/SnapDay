import SwiftUI
import ComposableArchitecture
import Application
import Dashboard
import HistoryList
import Details

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
