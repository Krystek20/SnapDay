import ActivityDetails
import ComposableArchitecture
import Reports
import SwiftUI

@MainActor
public struct ReportsCoordinatorView: View {

  @Bindable private var store: StoreOf<ReportsCoordinatorFeature>

  public init(store: StoreOf<ReportsCoordinatorFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      ReportsView(
        store: store.scope(state: \.reports, action: \.reports)
      )
    } destination: { store in
      switch store.state {
      case .activityDetails:
        if let store = store.scope(state: \.activityDetails, action: \.activityDetails) {
          ActivityDetailsView(store: store)
        }
      }
    }
  }
}
