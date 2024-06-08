import SwiftUI
import Application
import Utilities
import ComposableArchitecture

@main
struct SnapDayApp: App {

  private let store = Store(
    initialState: ApplicationFeature.State(),
    reducer: { ApplicationFeature() }
  )

  var body: some Scene {
    WindowGroup {
      ApplicationView(store: store)
    }
    .backgroundTask(.appRefresh(BackgroundUpdaterIdentifier.createDay.rawValue)) { @MainActor in
        store.send(.createDayBackgroundTaskCalled)
    }
  }
}
