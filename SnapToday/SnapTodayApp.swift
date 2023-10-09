import SwiftUI
import Application
import ComposableArchitecture

@main
struct SnapTodayApp: App {
  var body: some Scene {
    WindowGroup {
      ApplicationView(
        store: Store(
          initialState: ApplicationFeature.State(),
          reducer: { ApplicationFeature() }
        )
      )
    }
  }
}
