import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import DayActivityForm

public struct ActivityListView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ActivityListFeature>
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
    WithPerceptionTracking {
      content
        .maxWidth()
        .backgroundSoft
        .navigationTitle(String(localized: "Saved Activities", bundle: .module))
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
        .sheet(item: $store.scope(state: \.templateForm, action: \.templateForm)) { store in
          NavigationStack {
            DayActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
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
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        informationViewIfNeeded
        ForEach($store.items) { item in
          ListItemView(item: item) { action in
            store.send(.view(.listItemActionPerfomed(action)))
          }
          .contentShape(Rectangle())
          .onTapGesture {
            store.send(.view(.listItemActionPerfomed(.itemTapped(itemId: item.id, parentId: nil))))
          }
        }
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }

  @ViewBuilder
  private var informationViewIfNeeded: some View {
    WithPerceptionTracking {
      if let informationConfiguration = store.information {
        InformationView(configuration: informationConfiguration)
      }
    }
  }
}
