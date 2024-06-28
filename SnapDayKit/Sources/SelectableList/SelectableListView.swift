import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources

public struct SelectableListView: View {

  // MARK: - Properties

  private let store: StoreOf<SelectableListViewFeature>
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(store: StoreOf<SelectableListViewFeature>) {
    self.store = store
  }

  public var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(spacing: .zero) {
          itemsView
        }
        .padding(.horizontal, 15.0)
        .padding(.top, 15.0)
        .maxWidth()
      }
      .scrollIndicators(.hidden)
      .activityBackground
      .navigationTitle(store.title)
      .toolbar {
        WithPerceptionTracking {
          if store.isClearVisible {
            ToolbarItem(placement: .topBarTrailing) {
              Button(String(localized: "Clear", bundle: .module)) {
                store.send(.view(.clearTapped))
              }
              .foregroundStyle(Color.actionBlue)
              .font(.system(size: 12.0, weight: .bold))
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var itemsView: some View {
    WithPerceptionTracking {
      ForEach(store.itemsToDisplay) { item in
        HStack(spacing: 5.0) {
          switch item.leftItem {
          case .icon(let icon):
            ActivityImageView(
              data: icon?.data,
              size: 30.0,
              cornerRadius: 15.0
            )
          case .color(let rgbColor):
            rgbColor.color
              .frame(width: 30.0, height: 30.0)
              .clipShape(RoundedRectangle(cornerRadius: 15.0))
          case .none:
            EmptyView()
          }
          Text(item.name)
            .font(.system(size: 14.0, weight: titleWeight(item: item)))
            .foregroundStyle(titleColor(item: item))
          Spacer()
        }
        .padding(.all, 10.0)
        .contentShape(Rectangle())
        .onTapGesture {
          store.send(.view(.selected(item)))
        }
        if item != store.itemsToDisplay.last {
          Divider()
        }
      }
    }
  }

  private func titleWeight(item: Item) -> Font.Weight {
    store.selectedItem == item ? .semibold : .medium
  }

  private func titleColor(item: Item) -> Color {
    store.selectedItem == item ? .standardText : .sectionText
  }
}
