import ComposableArchitecture
import SwiftUI
import Dashboard
import HistoryList
import Details

public struct ApplicationView: View {

  // MARK: - Properties

  private let store: StoreOf<ApplicationFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ApplicationFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
      DashboardView(
        store: store.scope(
          state: \.dashboard,
          action: { .dashboard($0) }
        )
      )
    } destination: { state in
      switch state {
      case .historyList:
        CaseLet(
          /ApplicationFeature.Path.State.historyList,
           action: ApplicationFeature.Path.Action.historyList,
           then: HistoryListView.init
        )
      case .details:
        CaseLet(
          /ApplicationFeature.Path.State.details,
           action: ApplicationFeature.Path.Action.details,
           then: DetailsView.init
        )
      }
    }
  }
}
