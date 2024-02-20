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
      ScrollView {
        summaryView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 15.0)
        dayView(viewStore: viewStore)
          .padding(.horizontal, 15.0)
          .padding(.top, 15.0)
        timePeriods(viewStore: viewStore)
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
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            action: { 
              viewStore.send(.view(.reportButtonTapped))
            },
            label: {
              Image(systemName: "text.badge.checkmark")
                .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
            }
          )
        }
      }
    }
  }

  @ViewBuilder
  private func summaryView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    if let daySummary = viewStore.daySummary, daySummary.remaingDuration > .zero {
      SectionView(
        name: String(localized: "Time Summary", bundle: .module),
        rightContent: { },
        content: {
          TimeSummaryView(daySummary: daySummary)
        }
      )
    }
  }

  private func dayView(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    SectionView(
      name: String(localized: "Todays Activities", bundle: .module),
      rightContent: {
        HStack(spacing: 5.0) {
          Button(
            action: {
              viewStore.send(.view(.activityPresentationButtonTapped))
            },
            label: {
              icon(for: viewStore.activityListOption)
                .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
                .frame(width: 30.0, height: 30.0)
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
              .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
              .frame(width: 30.0, height: 30.0)
              .padding(.trailing, 5.0)
          }
        }
      },
      content: {
        DayView(
          isPastDay: false,
          activities: viewStore.dayActivities,
          activityListOption: viewStore.activityListOption,
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

  private func timePeriods(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    SectionView(
      name: String(localized: "Time Periods", bundle: .module),
      rightContent: { EmptyView() },
      content: {
        TimePeriodsView(
          timePeriods: viewStore.timePeriods,
          type: .grid,
          timePeriodTapped: { timePeriod in
            viewStore.send(.view(.timePeriodTapped(timePeriod)))
          }
        )
      }
    )
  }

  private func icon(for option: ActivityListOption) -> Image {
    switch option {
    case .collapsed:
      Image(systemName: "arrow.up.left.and.arrow.down.right")
    case .extended:
      Image(systemName: "arrow.down.right.and.arrow.up.left")
    }
  }
}
