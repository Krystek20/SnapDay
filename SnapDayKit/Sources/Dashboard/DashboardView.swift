import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm
import ActivityForm
import DayActivityTaskForm
import Models

public struct DashboardView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<DashboardFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views


  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          picker
            .padding(.horizontal, 15.0)
            .padding(.top, 65.0)

          periods
            .padding(.horizontal, 15.0)
            .padding(.top, 15.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)

        Switcher(
          title: store.activitiesPresentationTitle,
          leftArrowAction: {
            store.send(.view(.decreaseButtonTapped))
          },
          rightArrowAction: {
            store.send(.view(.increaseButtonTapped))
          }
        )
      }
      .activityBackground
      .sheet(item: $store.scope(state: \.activityList, action: \.activityList)) { store in
        NavigationStack {
          ActivityListView(store: store)
        }
        .presentationDetents([.medium, .large])
      }
      .sheet(item: $store.scope(state: \.editDayActivity, action: \.editDayActivity)) { store in
        NavigationStack {
          DayActivityFormView(store: store)
        }
        .presentationDetents([.large])
      }
      .sheet(item: $store.scope(state: \.addActivity, action: \.addActivity)) { store in
        NavigationStack {
          ActivityFormView(store: store)
        }
        .presentationDetents([.large])
      }
      .sheet(item: $store.scope(state: \.dayActivityTaskForm, action: \.dayActivityTaskForm)) { store in
        NavigationStack {
          DayActivityTaskFormView(store: store)
        }
        .presentationDetents([.large])
      }
      .task {
        store.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Dashboard", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          HStack {
            Button(
              action: {
                store.send(.view(.reportButtonTapped))
              },
              label: {
                Image(systemName: "chart.bar.xaxis")
                  .foregroundStyle(Color.actionBlue)
              }
            )
            Button(
              action: {
                store.send(.view(.todayButtonTapped))
              },
              label: {
                Image(systemName: "smallcircle.filled.circle")
                  .foregroundStyle(Color.actionBlue)
              }
            )
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            Button(
              action: {
                store.send(.view(.activityListButtonTapped))
              },
              label: {
                Image(systemName: "text.badge.plus")
                  .foregroundStyle(Color.actionBlue)
              }
            )
            Button(
              action: {
                store.send(.view(.oneTimeActivityButtonTapped))
              },
              label: {
                Image(systemName: "plus.circle")
                  .foregroundStyle(Color.actionBlue)
              }
            )
          }
        }
      }
    }
  }

  @MainActor
  private var picker: some View {
    WithPerceptionTracking {
      Picker(
        selection: $store.selectedPeriod,
        content: {
          ForEach(store.periods) { period in
            Text(period.name).tag(period)
          }
        },
        label: { EmptyView() }
      )
      .pickerStyle(.segmented)
    }
  }

  @MainActor
  private var periods: some View {
    WithPerceptionTracking {
      SectionView(
        name: store.activitiesPresentationTitle,
        rightContent: { },
        content: {
          periodsContent
            .formBackgroundModifier(padding: EdgeInsets(.zero))
        }
      )
    }
  }

  @ViewBuilder
  @MainActor
  private var periodsContent: some View {
    WithPerceptionTracking {
      if let activitiesPresentationType = store.activitiesPresentationType {
        switch activitiesPresentationType {
        case .monthsList(let timePeriods):
          monthsView(timePeriods: timePeriods)
        case .calendar(let calendarItems):
          calendarView(calendarItems: calendarItems)
        case .daysList(let style):
          dayList(daysSelectorStyle: style)
        }
      }
    }
  }

  private func monthsView(timePeriods: [TimePeriod]) -> some View {
    TimePeriodsView(
      timePeriods: timePeriods,
      timePeriodTapped: { timePeriod in
//          store.send(.view(.timePeriodTapped(timePeriod)))
      }
    )
  }

  @MainActor
  private func calendarView(calendarItems: [CalendarItemType]) -> some View {
    WithPerceptionTracking {
      CalendarView(
        selectedDay: $store.selectedDay,
        dayActivities: store.activities,
        calendarItems: calendarItems,
        daySummary: store.daySummary,
        dayViewShowButtonState: store.dayViewShowButtonState,
        informationConfiguration: store.dayInformation,
        dayViewOption: dayViewOption,
        showCompletedTapped: {
          store.send(.view(.showCompletedActivitiesTapped))
        },
        hideCompletedTapped: {
          store.send(.view(.hideCompletedActivitiesTapped))
        }
      )
    }
  }

  @MainActor
  private func dayList(daysSelectorStyle: DaysSelectorStyle) -> some View {
    WithPerceptionTracking {
      DaysSelectorView(
        selectedDay: $store.selectedDay,
        dayActivities: store.activities,
        daysSelectorStyle: daysSelectorStyle,
        daySummary: store.daySummary,
        dayViewShowButtonState: store.dayViewShowButtonState,
        informationConfiguration: store.dayInformation,
        dayViewOption: dayViewOption,
        showCompletedTapped: {
          store.send(.view(.showCompletedActivitiesTapped))
        },
        hideCompletedTapped: {
          store.send(.view(.hideCompletedActivitiesTapped))
        }
      )
    }
  }

  private var dayViewOption: DayViewOption {
    .all(
      DayViewAllActions(
        activityTapped: { dayActivity in
          store.send(.view(.dayActivityTapped(dayActivity)))
        },
        editTapped: { dayActivity in
          store.send(.view(.dayActivityEditTapped(dayActivity)))
        },
        removeTapped: { dayActivity in
          store.send(.view(.dayActivityRemoveTapped(dayActivity)))
        },
        activityTaskTapped: { dayActivity, dayActivityTask in
          store.send(.view(.dayActivityTaskTapped(dayActivity, dayActivityTask)))
        },
        editTaskTapped: { dayActivity, dayActivityTask in
          store.send(.view(.dayActivityEditTaskTapped(dayActivity, dayActivityTask)))
        },
        removeTaskTapped: { dayActivityTask in
          store.send(.view(.removeDayActivityTaskTapped(dayActivityTask)))
        }
      )
    )
  }
}
