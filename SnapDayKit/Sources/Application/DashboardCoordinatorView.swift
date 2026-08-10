import ComposableArchitecture
import Dashboard
import Plans
import SwiftUI

@MainActor
public struct DashboardCoordinatorView: View {

  @Bindable private var store: StoreOf<DashboardCoordinatorFeature>

  public init(store: StoreOf<DashboardCoordinatorFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      DashboardView(
        store: store.scope(state: \.dashboard, action: \.dashboard)
      )
    } destination: { store in
      switch store.state {
      case .planDetails:
        if let store = store.scope(state: \.planDetails, action: \.planDetails) {
          PlanDetailsView(store: store)
        }
      case .plans:
        if let store = store.scope(state: \.plans, action: \.plans) {
          PlansView(store: store)
        }
      }
    }
  }
}
