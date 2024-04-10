import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources

public struct MarkerListView: View {

  // MARK: - Properties

  private let store: StoreOf<MarkerListFeature>
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(store: StoreOf<MarkerListFeature>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 15.0) {
        markersView
      }
      .padding(.horizontal, 15.0)
      .padding(.top, 15.0)
    }
    .scrollIndicators(.hidden)
    .activityBackground
    .navigationTitle(String(localized: "Tag list", bundle: .module))
  }

  @ViewBuilder
  private var markersView: some View {
    switch store.type {
    case .tag(let selected, let available):
      ForEach(available) { marker in
        MarkerView(marker: marker)
          .onTapGesture {
            store.send(.view(.markerSelected(.tag(selected: marker))))
          }
          .opacity(selected == marker ? 1.0 : 0.3)
      }
    case .label(let selected, let available):
      ForEach(available) { marker in
        MarkerView(marker: marker)
          .onTapGesture {
            store.send(.view(.markerSelected(.label(selected: marker))))
          }
          .opacity(selected == marker ? 1.0 : 0.3)
      }
    }
  }
}
