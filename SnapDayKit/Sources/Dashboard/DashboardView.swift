import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm
import ActivityForm
import CalendarPicker
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
          dayListSection
            .padding(.horizontal, 15.0)
            .padding(.top, 65.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)

        Switcher(
          title: store.title,
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
        .presentationDetents([.large])

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
          DayActivityFormView(store: store)
        }
        .presentationDetents([.large])
      }
      .sheet(item: $store.scope(state: \.calendarPicker, action: \.calendarPicker)) { store in
        NavigationStack {
          CalendarPickerView(store: store)
        }
        .presentationDetents([.medium])
      }
      .alert($store.scope(state: \.dayActivityAlert, action: \.dayActivityAlert))
      .alert($store.scope(state: \.dayActivityTaskAlert, action: \.dayActivityTaskAlert))
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
                store.send(.view(.calendarButtonTapped))
              },
              label: {
                Image(systemName: "calendar")
                  .foregroundStyle(Color.actionBlue)
              }
            )
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
                store.send(.view(.addDayActivityButtonTapped))
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

  private var dayListSection: some View {
    WithPerceptionTracking {
      SectionView(
        name: store.title,
        rightContent: { },
        content: {
          dayList
            .formBackgroundModifier(padding: EdgeInsets(.zero))
        }
      )
    }
  }

  private var dayList: some View {
    WithPerceptionTracking {
      DaysSelectorView(
        selectedDay: $store.selectedDay,
        dayActivities: store.activities,
        daySummary: store.daySummary,
        dayViewShowButtonState: store.dayViewShowButtonState,
        informationConfiguration: store.dayInformation,
        dayActivityAction: { action in
          store.send(.view(.dayActivityActionPerfomed(action)))
        },
        showCompletedTapped: {
          store.send(.view(.showCompletedActivitiesTapped))
        },
        hideCompletedTapped: {
          store.send(.view(.hideCompletedActivitiesTapped))
        }
      )
    }
  }
}
