import ComposableArchitecture
import Resources
import SwiftUI
import UiComponents

@MainActor
public struct PlansView: View {

  // MARK: - Properties

  private let store: StoreOf<PlansFeature>

  // MARK: - Initialization

  public init(store: StoreOf<PlansFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    ScrollView { }
      .maxWidth()
      .background
      .navigationTitle(String(localized: "Plans", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        store.send(.view(.appeared))
      }
  }
}
