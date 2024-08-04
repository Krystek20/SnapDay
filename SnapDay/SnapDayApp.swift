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
        .onOpenURL { url in
          store.send(.handleUrl(url))
        }
    }
    .backgroundTask(.appRefresh(BackgroundUpdaterIdentifier.createDay.rawValue)) { @MainActor in
        store.send(.createDayBackgroundTaskCalled)
    }
  }
}
