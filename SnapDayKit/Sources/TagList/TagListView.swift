import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources

public struct TagListView: View {

  // MARK: - Properties

  private let store: StoreOf<TagListFeature>
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(store: StoreOf<TagListFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        LazyVGrid(columns: columns, spacing: 15.0) {
          ForEach(viewStore.availableTags) { tag in
            TagView(tag: tag)
              .onTapGesture {
                viewStore.send(.view(.tagSelected(tag)))
              }
              .opacity(viewStore.tag == tag ? 1.0 : 0.3)
          }
        }
        .padding(.horizontal, 15.0)
        .padding(.top, 15.0)
      }
      .scrollIndicators(.hidden)
      .activityBackground
      .navigationTitle(String(localized: "Tag list", bundle: .module))
    }
  }
}
