import SwiftUI
import Application
import Utilities
import ComposableArchitecture
import Repositories

@main
struct SnapDayApp: App {

  @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

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
  }
}
