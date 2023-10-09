import SwiftUI
import ComposableArchitecture
import Resources

public struct DashboardView: View {

  // MARK: - Properties

  private let store: StoreOf<DashboardFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: 25.0) {
        VStack(alignment: .leading, spacing: 2.0) {
          Text("Hi Krystian,")
            .font(Fonts.Quicksand.regular.swiftUIFont(size: 12.0))
          Text("Welcome back 👋")
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 10.0))
        }
        
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
}
