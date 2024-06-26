import SwiftUI
import ComposableArchitecture
import Application
import Dashboard
import MarkerForm
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

#Preview("MarkerFormView") {
  MarkerFormView(
    store: Store(
      initialState: MarkerFormFeature.State(markerType: .tag),
      reducer: { MarkerFormFeature() }
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
