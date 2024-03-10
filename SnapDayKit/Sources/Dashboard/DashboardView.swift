import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm
import ActivityForm
import Models

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
      ZStack(alignment: .top) {
        ScrollView {
          picker(viewStore: viewStore)
            .padding(.horizontal, 15.0)
            .padding(.top, 65.0)

          periods(viewStore: viewStore)
            .padding(.horizontal, 15.0)
            .padding(.top, 15.0)

          summaryOnTheChart(viewStore: viewStore)
            .padding(.horizontal, 15.0)
            .padding(.top, 15.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)

        Switcher(
          title: viewStore.activitiesPresentationTitle,
          leftArrowAction: {
            viewStore.send(.view(.decreaseButtonTapped))
          },
          rightArrowAction: {
            viewStore.send(.view(.increaseButtonTapped))
          }
        )
      }
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
      .navigationTitle(String(localized: "Dashboard", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            Button(
              action: {
                viewStore.send(.view(.reportButtonTapped))
              },
              label: {
                Image(systemName: "text.badge.checkmark")
                  .foregroundStyle(Color.lavenderBliss)
              }
            )

            Menu {
              Button(String(localized: "One-time activity", bundle: .module), action: {
                viewStore.send(.view(.oneTimeActivityButtonTapped))
              })
              Button(String(localized: "Activity list", bundle: .module), action: {
                viewStore.send(.view(.activityListButtonTapped))
              })
            } label: {
              Image(systemName: "plus.app")
                .foregroundStyle(Color.lavenderBliss)
            }
          }
        }
      }
    }
  }
  @MainActor
  private func picker(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    Picker(
      selection: viewStore.$selectedPeriod,
      content: {
        ForEach(viewStore.periods) { period in
          Text(period.name).tag(period)
        }
      },
      label: { EmptyView() }
    )
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private func summaryOnTheChart(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    if let linearChartValues = viewStore.linearChartValues {
      SectionView(
        name: String(localized: "Summary", bundle: .module),
        rightContent: { EmptyView() },
        content: {
          LinearChartView(points: linearChartValues.points, expectedPoints: linearChartValues.expectedPoints)
            .frame(height: 200.0)
            .padding(.vertical, 15.0)
            .formBackgroundModifier()
        }
      )
    }
  }

  @MainActor
  private func periods(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    SectionView(
      name: viewStore.activitiesPresentationTitle,
      rightContent: { },
      content: {
        periodsContent(viewStore: viewStore)
          .formBackgroundModifier(padding: EdgeInsets(.zero))
      }
    )
  }

  @ViewBuilder
  @MainActor
  private func periodsContent(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    if let activitiesPresentationType = viewStore.activitiesPresentationType {
      switch activitiesPresentationType {
      case .monthsList(let timePeriods):
        monthsView(timePeriods: timePeriods, viewStore: viewStore)
      case .calendar(let calendarItems):
        calendarView(calendarItems: calendarItems, viewStore: viewStore)
      case .daysList(let style):
        dayList(daysSelectorStyle: style, viewStore: viewStore)
      }
    }
  }

  private func monthsView(timePeriods: [TimePeriod], viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    TimePeriodsView(
      timePeriods: timePeriods,
      timePeriodTapped: { timePeriod in
//          viewStore.send(.view(.timePeriodTapped(timePeriod)))
      }
    )
  }

  @MainActor
  private func calendarView(calendarItems: [CalendarItemType], viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    CalendarView(
      selectedDay: viewStore.$selectedDay,
      dayActivities: viewStore.activities,
      calendarItems: calendarItems,
      daySummary: viewStore.daySummary,
      dayViewShowButtonState: viewStore.dayViewShowButtonState,
      dayActivityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityTapped(dayActivity)))
      },
      dayActivityEditTapped: { dayActivity in
        viewStore.send(.view(.dayActivityEditTapped(dayActivity)))
      },
      removeDayActivityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityRemoveTapped(dayActivity)))
      },
      showCompletedTapped: {
        viewStore.send(.view(.showCompletedActivitiesTapped))
      },
      hideCompletedTapped: {
        viewStore.send(.view(.hideCompletedActivitiesTapped))
      }
    )
  }

  @MainActor
  private func dayList(daysSelectorStyle: DaysSelectorStyle, viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    DaysSelectorView(
      selectedDay: viewStore.$selectedDay,
      dayActivities: viewStore.activities,
      daysSelectorStyle: daysSelectorStyle,
      daySummary: viewStore.daySummary,
      dayViewShowButtonState: viewStore.dayViewShowButtonState,
      dayActivityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityTapped(dayActivity)))
      },
      dayActivityEditTapped: { dayActivity in
        viewStore.send(.view(.dayActivityEditTapped(dayActivity)))
      },
      removeDayActivityTapped: { dayActivity in
        viewStore.send(.view(.dayActivityRemoveTapped(dayActivity)))
      },
      showCompletedTapped: {
        viewStore.send(.view(.showCompletedActivitiesTapped))
      },
      hideCompletedTapped: {
        viewStore.send(.view(.hideCompletedActivitiesTapped))
      }
    )
  }
}
