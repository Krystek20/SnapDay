import SwiftUI
import ComposableArchitecture
import UiComponents
import Models
import Resources
import ActivityList
import DayActivityForm

@MainActor
public struct PlanDetailsView: View {

  // MARK: - Properties

  private let store: StoreOf<PlanDetailsFeature>

  // MARK: - Initialization

  public init(store: StoreOf<PlanDetailsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        content(viewStore: viewStore)
          .padding(.top, 15.0)
          .padding(.horizontal, 15.0)
      }
      .maxWidth()
      .scrollIndicators(.hidden)
      .activityBackground
      .navigationTitle(name(for: viewStore.plan))
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
    }
  }

  private func content(viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    VStack(spacing: 30.0) {
      SectionView(
        name: String(localized: "Summary", bundle: .module),
        rightContent: { EmptyView() },
        content: {
          summaryView(viewStore: viewStore)
        }
      )
      SectionView(
        name: String(localized: "Activities", bundle: .module),
        rightContent: { EmptyView() },
        content: {
          VStack(spacing: 20.0) {
            segmentView(viewStore: viewStore)
            daysView(viewStore: viewStore)
          }
        }
      )
    }
  }

  @ViewBuilder
  private func summaryView(viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    switch viewStore.summaryType {
    case .chart(let points, let expectedPoints):
      LinearChartView(points: points, expectedPoints: expectedPoints)
        .frame(height: 200.0)
    case .circle(let progress):
      CircularProgressView(progress: progress)
        .frame(height: 200.0)
    }
  }

  private func segmentView(viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    Picker(
      selection: viewStore.$presentationMode,
      content: {
        Text("List", bundle: .module).tag(PresentationMode.list)
        Text("Grid", bundle: .module).tag(PresentationMode.grid)
      },
      label: { EmptyView() }
    )
    .pickerStyle(.segmented)
  }

  private func daysView(viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    LazyVStack(spacing: 15.0) {
      ForEach(viewStore.days) { day in
        dayViewSection(day, viewStore: viewStore)
      }
    }
  }

  private func dayViewSection(_ day: Day, viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    SectionView(
      label: {
        Text(day.formattedDate)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 18.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      },
      rightContent: {
        Button(
          action: {
            viewStore.send(.view(.addButtonTapped(day)))
          }, label: {
            Text(String(localized: "Add", bundle: .module))
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
          }
        )
      },
      content: {
        if day.activities.isEmpty {
          noActivitiesInformation(isPastDay: day.isOlderThenToday ?? false)
        } else {
          dayView(day, viewStore: viewStore)
        }
      }
    )
  }

  @ViewBuilder
  private func noActivitiesInformation(isPastDay: Bool) -> some View {
    let configuration: EmptyDayConfiguration = isPastDay ? .pastDay : .todayOrFuture
    InformationView(configuration: configuration)
  }

  @ViewBuilder
  private func dayView(_ day: Day, viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    switch viewStore.presentationMode {
    case .list:
      listDayView(day, viewStore: viewStore)
    case .grid:
      gridDayView(day, viewStore: viewStore)
    }
  }

  private func listDayView(_ day: Day, viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    DayView(
      isPastDay: day.isOlderThenToday ?? false,
      activities: day.activities.sortedByName,
      activityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityTapped(dayActivity)))
      },
      editTapped: { dayActivity in
        viewStore.send(.view(.dayActivityEditTapped(dayActivity, day)))
      },
      removeTapped: { dayActivity in
        viewStore.send(.view(.removeDayActivityTapped(dayActivity, day)))
      }
    )
  }

  private func gridDayView(_ day: Day, viewStore: ViewStoreOf<PlanDetailsFeature>) -> some View {
    DayGridView(
      isPastDay: day.isOlderThenToday ?? false,
      activities: day.activities.sortedByName,
      activityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityTapped(dayActivity)))
      },
      editTapped: { dayActivity in
        viewStore.send(.view(.dayActivityEditTapped(dayActivity, day)))
      },
      removeTapped: { dayActivity in
        viewStore.send(.view(.removeDayActivityTapped(dayActivity, day)))
      }
    )
  }


  private func dayActivities(_ dayActivities: [DayActivity]) -> some View {
    LazyVStack(spacing: .zero) {
      ForEach(dayActivities) { dayActivity in
        Text(dayActivity.activity.name)
          .formBackgroundModifier
      }
    }
  }

  // MARK: - Private

  private func name(for plan: Plan) -> String {
    switch plan.type {
    case .daily:
      String(localized: "Daily", bundle: .module)
    case .weekly:
      String(localized: "Weekly", bundle: .module)
    case .monthly:
      String(localized: "Monthly", bundle: .module)
    case .quarterly:
      String(localized: "Quarterly", bundle: .module)
    case .custom:
      plan.name
    }
  }
}
