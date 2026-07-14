import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import DayActivityForm

public struct ActivityListView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<ActivityListFeature>
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(store: StoreOf<ActivityListFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    content
      .maxWidth()
      .backgroundSoft
      .navigationTitle(store.navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .searchable(
        text: $store.searchText,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: String(localized: "Search for Activity", bundle: .module)
      )
      .onAppear {
        store.send(.view(.appeared))
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(String(localized: "Cancel", bundle: .module)) {
            store.send(.view(.cancelButtonTapped))
          }
          .font(.system(size: 12.0, weight: .bold))
          .foregroundStyle(Color.actionBlue)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            action: {
              store.send(.view(.newButtonTapped))
            },
            label: {
              Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.actionBlue)
            }
          )
        }
      }
      .toolbarBackground(Color.backgroundSoft, for: .navigationBar)
      .safeAreaInset(edge: .bottom) {
        if store.isSelectionMode {
          Button(
            action: { store.send(.view(.selectionConfirmed)) },
            label: { Text(selectionButtonTitle) }
          )
          .buttonStyle(PrimaryButtonStyle())
          .padding(.horizontal, 15.0)
          .padding(.vertical, 10.0)
          .background(Color.background)
        }
      }
      .sheet(item: $store.scope(state: \.templateForm, action: \.templateForm)) { store in
        NavigationStack {
          DayActivityFormView(store: store)
        }
        .presentationDetents([.large])
      }
  }

  private var content: some View {
    ScrollView {
      activityList
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .scrollIndicators(.hidden)
  }

  private var activityList: some View {
    VStack(spacing: .zero) {
      informationViewIfNeeded
      ForEach($store.items) { item in
        if store.isSelectionMode, !item.wrappedValue.isForm {
          selectionItem(item.wrappedValue)
        } else {
          ListItemView(item: item) { action in
            store.send(.view(.listItemActionPerfomed(action)))
          }
          .contentShape(Rectangle())
          .onTapGesture {
            store.send(.view(.listItemActionPerfomed(.itemTapped(itemId: item.id, parentId: nil))))
          }
        }
      }
    }
    .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  @ViewBuilder
  private var informationViewIfNeeded: some View {
    if let informationConfiguration = store.information {
      InformationView(configuration: informationConfiguration)
    }
  }

  @ViewBuilder
  private func selectionItem(_ item: ListItem) -> some View {
    if let activityID = UUID(uuidString: item.id) {
      Button {
        store.send(.view(.activitySelectionTapped(activityID)))
      } label: {
        ListItemView(item: item) {
          Image(systemName: store.selectedActivityIDs.contains(activityID) ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20.0))
            .foregroundStyle(
              store.selectedActivityIDs.contains(activityID)
                ? Color.actionBlue
                : Color.sectionText
            )
        }
      }
      .buttonStyle(.plain)
    }
  }

  private var selectionButtonTitle: String {
    if store.selectedActivityIDs.count == 1 {
      return String(localized: "Add 1 activity", bundle: .module)
    }
    return String(
      localized: "Add \(store.selectedActivityIDs.count) activities",
      bundle: .module
    )
  }
}
