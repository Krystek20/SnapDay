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
  @FocusState private var focus: DayNewField?
  @State private var alertSize = CGSize.zero

  private var additionalButtomPadding: Double {
    guard store.alert != nil else { return .zero }
    return alertSize.height + 15.0
  }

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          Spacer()
            .frame(height: 50.0)
          dayList
            .padding(.horizontal, 15.0)
            .padding(.top, 15.0)
            .padding(.bottom, 15.0 + additionalButtomPadding)
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

        alertViewIfVisible
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
            .modifier(SaveActivityTipModifier())
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

  @ViewBuilder
  private var alertViewIfVisible: some View {
    WithPerceptionTracking {
      if let alertConfiguration = store.alert?.configuration {
        VStack {
          Spacer()
          ComplateAlertView(
            configuration: alertConfiguration,
            confirmButtonTapped: {
              store.send(.view(.confirmAlertButtonTapped))
            },
            cancelButtonTapped: {
              store.send(.view(.cancelAlertButtonTapped))
            }
          )
          .extractSize(in: $alertSize)
          .padding(.all, 15.0)
        }
      }
    }
  }

  private var dayList: some View {
    WithPerceptionTracking {
      DaysSelectorView(
        selectedDay: $store.selectedDay,
        newForms: DayView.NewForms(
          newActivity: $store.newActivity,
          newActivityTask: $store.newActivityTask,
          focus: $focus,
          newActivityAction: { action in
            store.send(.view(.newActivityActionPerformed(action)))
          }
        ),
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
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }
}

struct SaveActivityTipModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      return content
        .popoverTip(SaveActivityTip())
    } else {
      return content
    }
  }
}
