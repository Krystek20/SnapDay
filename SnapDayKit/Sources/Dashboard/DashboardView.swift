import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import ActivityList
import DayActivityForm
import CalendarPicker
import Models
import Friends
import ManageActivity
import Utilities

public struct DashboardView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<DashboardFeature>
  @Environment(\.calendar) private var calendar
  @Environment(\.locale) private var locale
  @State private var alertSize = CGSize.zero

  private var additionalButtomPadding: Double {
    guard store.day.alert != nil else { return .zero }
    return alertSize.height + 15.0
  }

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    @Bindable var dayStore = store.scope(state: \.day, action: \.day)

    ZStack(alignment: .top) {
      ScrollView {
        dashboardContent
          .padding(.horizontal, 15.0)
          .padding(.top, 15.0)
          .padding(.bottom, 15.0 + additionalButtomPadding)
      }
      .maxWidth()
      .scrollIndicators(.hidden)
      .safeAreaInset(edge: .top, spacing: .zero) {
        Switcher(
          title: store.title,
          titleAction: {
            store.send(.view(.calendarButtonTapped))
          },
          leftArrowAction: {
            store.send(.view(.decreaseButtonTapped))
          },
          rightArrowAction: {
            store.send(.view(.increaseButtonTapped))
          }
        )
      }

      aiAssistantButton

      alertViewIfVisible
    }
    .background
    .sheet(item: $dayStore.scope(state: \.activityList, action: \.activityList)) { store in
      NavigationStack {
        ActivityListView(store: store)
      }
      .presentationDetents([.large])
    }
    .sheet(item: $dayStore.scope(state: \.editDayActivity, action: \.editDayActivity)) { store in
      NavigationStack {
        DayActivityFormView(store: store)
      }
      .presentationDetents([.large])
    }
    .sheet(item: $dayStore.scope(state: \.dayActivityTaskForm, action: \.dayActivityTaskForm)) { store in
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
    .sheet(item: $store.scope(state: \.friends, action: \.friends)) { store in
      NavigationStack {
        FriendsView(store: store)
      }
      .presentationDetents([.large])
    }
    .sheet(item: $store.scope(state: \.manageActivity, action: \.manageActivity)) { store in
      NavigationStack {
        ManageActivityView(store: store)
      }
      .presentationDetents([.large])
      .interactiveDismissDisabled()
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
          Menu(
            content: {
              Button(
                action: {
                  store.send(.day(.view(.toggleShowCompletedActivities)))
                },
                label: {
                  Text("Show completed", bundle: .module)
                  if !store.day.hideCompleted {
                    Image(systemName: "checkmark.circle.fill")
                  }
                }
              )
              Button(
                action: {
                  store.send(.day(.view(.toggleShowTasks)))
                },
                label: {
                  Text("Show tasks", bundle: .module)
                  if !store.day.hideTasks {
                    Image(systemName: "checkmark.circle.fill")
                  }
                }
              )
              Button(
                action: {
                  store.send(.notifications(.view(.settingsTapped)))
                },
                label: {
                  Text("Notifications", bundle: .module)
                  Image(systemName: "bell")
                }
              )
            }, label: {
              Image(systemName: "gearshape.circle.fill")
                .foregroundStyle(Color.actionBlue)
            }
          )
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack {
          Button(
            action: {
              store.send(.view(.showFriendsTapped))
            },
            label: {
              Image(systemName: "person.2.circle.fill")
                .foregroundStyle(Color.actionBlue)
            }
          )

          Button(
            action: {
              store.send(.day(.view(.activityListButtonTapped)))
            },
            label: {
              Image(systemName: "list.bullet.circle.fill")
                .foregroundStyle(Color.actionBlue)
            }
          )
          .modifier(SaveActivityTipModifier())
          Button(
            action: {
              store.send(.day(.view(.newButtonTapped)))
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

  @ViewBuilder
  private var alertViewIfVisible: some View {
    if let alertConfiguration = store.day.alert?.configuration {
      VStack {
        Spacer()
        ComplateAlertView(
          configuration: alertConfiguration,
          confirmButtonTapped: {
            store.send(.day(.view(.confirmAlertButtonTapped)))
          },
          cancelButtonTapped: {
            store.send(.day(.view(.cancelAlertButtonTapped)))
          }
        )
        .extractSize(in: $alertSize)
        .padding(.all, 15.0)
      }
    }
  }

  private var dashboardContent: some View {
    VStack(spacing: 15.0) {
      plansSummary
      notificationPrompt
      dayList
    }
  }

  @ViewBuilder
  private var notificationPrompt: some View {
    if store.shouldShowNotificationPrompt {
      DashboardNotificationPromptView(
        dismissAction: {
        store.send(.notifications(.view(.promptDismissed)))
        },
        turnOnAction: {
        store.send(.notifications(.view(.turnOnTapped)))
        }
      )
    }
  }

  private var plansSummary: some View {
    DashboardPlansSectionView(
      configurations: planSummaryConfigurations,
      planAction: planSummaryAction,
      allPlansAction: {
        store.send(.plans(.view(.allPlansTapped)))
      }
    )
  }

  private var planSummaryAction: ((Int) -> Void)? {
    guard !store.plans.summaries.isEmpty else { return nil }

    return { index in
      guard store.plans.summaries.indices.contains(index) else { return }
      store.send(.plans(.view(.planTapped(store.plans.summaries[index].plan))))
    }
  }

  private var planSummaryConfigurations: [DashboardPlansSummaryView.Configuration] {
    guard !store.plans.summaries.isEmpty else {
      return [
        DashboardPlansSummaryView.Configuration(
          title: String(localized: "No active plans", bundle: .module),
          subtitle: String(localized: "Scheduled plans will appear here.", bundle: .module)
        )
      ]
    }

    return store.plans.summaries.map {
      DashboardPlansSummaryView.Configuration(
        summary: $0,
        calendar: calendar.utcCalendar,
        locale: locale
      )
    }
  }

  private var dayList: some View {
    @Bindable var dayStore = store.scope(state: \.day, action: \.day)

    return DaysSelectorView(
      selectedDay: $dayStore.selectedDay,
      items: $dayStore.items,
      daySummary: dayStore.daySummary,
      informationConfiguration: dayStore.dayInformation,
      dayActivityAction: { action in
        dayStore.send(.view(.listItemActionPerformed(action)))
      }
    )
    .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  private var aiAssistantButton: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(
          action: {
            store.send(.view(.assistantButtonTapped))
          },
          label: {
            Image(systemName: "sparkles")
              .foregroundStyle(Color.pureWhite)
              .font(.system(size: 20.0))
              .padding(.all, 8.0)
              .background(
                Circle()
                  .fill(Color.actionBlue)
              )
          }
        )
      }
    }
    .padding(20.0)
  }
}

struct SaveActivityTipModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .popoverTip(SaveActivityTip())
  }
}
