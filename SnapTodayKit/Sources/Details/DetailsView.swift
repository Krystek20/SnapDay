import SwiftUI
import ComposableArchitecture

public struct DetailsView: View {

  // MARK: - Properties

  private let store: StoreOf<DetailsFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DetailsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Text("DetailsView")
    }
  }
}
