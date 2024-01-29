import SwiftUI
import Application
import ComposableArchitecture

@main
struct SnapDayApp: App {
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
