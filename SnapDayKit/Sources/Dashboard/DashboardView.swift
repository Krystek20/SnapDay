import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm

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
      ScrollView {
        dayView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 15.0)
        plansView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 10.0)
      }
      .maxWidth()
      .scrollIndicators(.hidden)
      .activityBackground
      .sheet(
        store: store.scope(
          state: \.$activityList,
          action: { .activityList($0) }
        ),
        content: { store in
          NavigationStack {
            ActivityListView(store: store)
          }
          .presentationDetents([.medium, .large])
        }
      )
      .sheet(
        store: store.scope(
          state: \.$editDayActivity,
          action: { .editDayActivity($0) }
        ),
        content: { store in
          NavigationStack {
            DayActivityFormView(store: store)
          }
          .presentationDetents([.medium])
        }
      )
      .task {
        viewStore.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Dashboard", bundle: .module))
    }
  }

  @ViewBuilder
  private func dayView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    SectionView(
      name: String(localized: "Todays Activities", bundle: .module),
      rightContent: {
        Menu {
          Button(String(localized: "One-time activity", bundle: .module), action: {
            viewStore.send(.view(.oneTimeActivityButtonTapped))
          })
          Button(String(localized: "Activity list", bundle: .module), action: {
            viewStore.send(.view(.activityListButtonTapped))
          })
        } label: {
          Text(String(localized: "Add", bundle: .module))
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
        }
      },
      content: {
        DayView(
          isPastDay: false,
          activities: viewStore.dayActivities,
          activityTapped: { activity in
            viewStore.send(.view(.dayActivityTapped(activity)))
          },
          editTapped: { activity in
            viewStore.send(.view(.dayActivityEditTapped(activity)))
          },
          removeTapped: { activity in
            viewStore.send(.view(.dayActivityRemoveTapped(activity)))
          }
        )
      }
    )
  }

  private func plansView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    SectionView(
      name: String(localized: "Plans", bundle: .module),
      rightContent: { EmptyView() },
      content: {
        PlansView(
          plans: viewStore.plans,
          planTapped: { plan in
            viewStore.send(.view(.planTapped(plan)))
          }
        )
      }
    )
  }
}
