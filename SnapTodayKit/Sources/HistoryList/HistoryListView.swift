import SwiftUI
import ComposableArchitecture

public struct HistoryListView: View {

  // MARK: - Properties

  private let store: StoreOf<HistoryListFeature>

  // MARK: - Initialization

  public init(store: StoreOf<HistoryListFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Button {
        viewStore.send(.startGameTapped)
      } label: {
        Text("Start game")
          .padding(
            EdgeInsets(
              top: 15.0,
              leading: 35.0,
              bottom: 15.0,
              trailing: 35.0
            )
          )
          .overlay {
            RoundedRectangle(cornerRadius: 8.0)
              .stroke(Color.gray, lineWidth: 2.0)
          }
      }
    }
  }
}
