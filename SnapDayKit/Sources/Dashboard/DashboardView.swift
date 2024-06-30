import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm
import CalendarPicker
import Models

public struct DashboardView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<DashboardFeature>
  @FocusState private var focus: DashboardFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views


  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          dayList
            .padding(.horizontal, 15.0)
            .padding(.top, 65.0)
            .padding(.bottom, 15.0)
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
      .bind($store.focus, to: $focus)
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
                store.send(.view(.todayButtonTapped))
              },
              label: {
                Image(systemName: "smallcircle.filled.circle.fill")
                  .foregroundStyle(Color.actionBlue)
              }
            )
            Button(
              action: {
                store.send(.view(.calendarButtonTapped))
              },
              label: {
                Image(systemName: "calendar.circle.fill")
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
                Image(systemName: "list.bullet.circle.fill")
                  .foregroundStyle(Color.actionBlue)
              }
            )
            .modifier(TipKitViewModifier())
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
      }
    }
  }

  private var dayList: some View {
    WithPerceptionTracking {
      DaysSelectorView(
        selectedDay: $store.selectedDay,
        newActivity: $store.newActivity,
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
        },
        cancelNewActivity: {
          store.send(.view(.cancelNewButtonTapped))
        }
      )
      .focused($focus, equals: .name)
      .onSubmit {
        store.send(.view(.doneNewButtonTapped))
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }
}

struct TipKitViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      return content
        .popoverTip(SaveActivityTip())
    } else {
      return content
    }
  }
}
