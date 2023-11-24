import SwiftUI
import ComposableArchitecture
import ActivityForm
import UiComponents
import Resources

public struct DashboardView: View {

  // MARK: - Properties

  private let store: StoreOf<DashboardFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store

    #warning("Move it")
    let appearance = UINavigationBarAppearance()
    appearance.backgroundColor = Colors.lightGray.color

    appearance.largeTitleTextAttributes = [
      .font: Fonts.Quicksand.bold.font(size: 28.0),
      .foregroundColor: Colors.deepSpaceBlue.color
    ]
    appearance.titleTextAttributes = [
      .font: Fonts.Quicksand.bold.font(size: 18.0),
      .foregroundColor: Colors.deepSpaceBlue.color
    ]

    let scrollEdgeAppearance = appearance.copy()
    scrollEdgeAppearance.shadowImage = nil
    scrollEdgeAppearance.shadowColor = nil

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        headerView(userName: viewStore.userName)
          .padding(.horizontal, 15.0)
          .padding(.top, 15.0)
        dayView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 10.0)
        plansView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 10.0)
        activitiesSection(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 10.0)
      }
      .scrollIndicators(.hidden)
      .activityBackground
      .sheet(
        store: store.scope(
          state: \.$addActivity,
          action: { .addActivity($0) }
        ),
        content: { store in
          NavigationStack {
            ActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
      )
      .task {
        viewStore.send(.view(.appeared))
      }
    }
  }

  private func headerView(userName: String) -> some View {
    VStack(alignment: .leading, spacing: 2.0) {
      if !userName.isEmpty {
        Text("Hi \(userName),", bundle: .module)
          .font(Fonts.Quicksand.regular.swiftUIFont(size: 30.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
      Text("Welcome back 👋", bundle: .module)
        .titleTextStyle
    }
    .maxWidth()
  }

  @ViewBuilder
  private func dayView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    section(
      name: String(localized: "Todays Activities", bundle: .module),
      buttonActionName: String(localized: "New", bundle: .module),
      onTap: {

      },
      content: DayView(
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
    )
  }

  private func plansView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    section(
      name: String(localized: "Plans", bundle: .module),
      buttonActionName: String(localized: "New", bundle: .module),
      onTap: {

      },
      content: PlansView(plans: viewStore.plans)
    )
  }

  private func activitiesSection(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    section(
      name: String(localized: "Activities", bundle: .module),
      buttonActionName: String(localized: "New", bundle: .module),
      onTap: {
        viewStore.send(.view(.addButtonTapped))
      }, 
      content: ActivitiesView(
        activities: viewStore.activities,
        activityTapped: { activity in
          viewStore.send(.view(.activityTapped(activity)))
        },
        activityEditTapped: { activity in
          viewStore.send(.view(.activityEditTapped(activity)))
        }
      )
    )
  }

  private func section(
    name: String,
    buttonActionName: String,
    onTap: @escaping () -> Void,
    content: some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 15.0) {
      HStack {
        Text(name)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 22.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
        Spacer()
        Button(action: onTap) {
          Text(buttonActionName)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
        }
      }
      content
    }
    .maxWidth()
  }
}
