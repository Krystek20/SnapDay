import SwiftUI
import ComposableArchitecture
import UiComponents
import Models
import Resources
import ActivityList
import DayActivityForm
import ActivityForm

@MainActor
public struct TimePeriodDetailsView: View {

  // MARK: - Properties

  private let store: StoreOf<TimePeriodDetailsFeature>

  // MARK: - Initialization

  public init(store: StoreOf<TimePeriodDetailsFeature>) {
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
      .navigationTitle(name(for: viewStore.timePeriod))
      .task {
        viewStore.send(.view(.appear))
      }
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
    }
  }

  private func content(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    VStack(spacing: 30.0) {
      summaryOnTheChart(viewStore: viewStore)
      summaryByTag(viewStore: viewStore)
      summaryByTime(viewStore: viewStore)
      periods(viewStore: viewStore)
    }
  }

  private func summaryOnTheChart(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    SectionView(
      name: String(localized: "Summary", bundle: .module),
      rightContent: { EmptyView() },
      content: {
        summaryView(viewStore: viewStore)
      }
    )
  }

  private func summaryByTag(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    SectionView(
      label: {
        Text("By Tags", bundle: .module)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 18.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      },
      rightContent: { EmptyView() },
      content: {
        TimePeriodSummaryView(
          selectedTag: viewStore.$selectedTag,
          timePeriodActivitySections: viewStore.timePeriodActivitySections
        )
      }
    )
  }

  @ViewBuilder
  private func summaryByTime(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    if let daySummary = viewStore.daySummary {
      SectionView(
        name: String(localized: "Summary by time", bundle: .module),
        rightContent: { },
        content: {
          TimeSummaryView(daySummary: daySummary)
        }
      )
    }
  }

  @ViewBuilder
  private func periods(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    if let activitiesPresentationType = viewStore.activitiesPresentationType {
      SectionView(
        label: {
          Text(activitiesPresentationType.title)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 18.0))
            .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
        },
        rightContent: {
          Menu {
            Button(String(localized: "One-time activity", bundle: .module), action: {
              guard let selectedDay = viewStore.selectedDay else { return }
              viewStore.send(.view(.oneTimeActivityButtonTapped(selectedDay)))
            })
            Button(String(localized: "Activity list", bundle: .module), action: {
              guard let selectedDay = viewStore.selectedDay else { return }
              viewStore.send(.view(.activityListButtonTapped(selectedDay)))
            })
          } label: {
            Text(String(localized: "Add", bundle: .module))
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
          }
        },
        content: {
          switch activitiesPresentationType {
          case .months(let timePeriods):
            TimePeriodsView(
              timePeriods: timePeriods,
              type: .list,
              timePeriodTapped: { timePeriod in
                #warning("Handle me")
                print(timePeriod.dateRange)
    //            viewStore.send(.view(.planTapped(plan)))
              }
            )
          case .month(let monthName, let calendarItem):
            CalendarView(
              selectedDay: viewStore.$selectedDay,
              calendarItems: calendarItem,
              dayActivityTapped: { dayActivity in
                viewStore.send(.view(.dayActivityTapped(dayActivity)))
              },
              dayActivityEditTapped: { dayActivity, day in
                viewStore.send(.view(.dayActivityEditTapped(dayActivity, day)))
              },
              removeDayActivityTapped: { dayActivity, day in
                viewStore.send(.view(.removeDayActivityTapped(dayActivity, day)))
              }
            )
          case .days(let days):
            DaysSelectorView(
              selectedDay: viewStore.$selectedDay,
              days: days,
              dayActivityTapped: { dayActivity in
                viewStore.send(.view(.dayActivityTapped(dayActivity)))
              },
              dayActivityEditTapped: { dayActivity, day in
                viewStore.send(.view(.dayActivityEditTapped(dayActivity, day)))
              },
              removeDayActivityTapped: { dayActivity, day in
                viewStore.send(.view(.removeDayActivityTapped(dayActivity, day)))
              }
            )
          }
        }
      )
    }
  }

  @ViewBuilder
  private func summaryView(viewStore: ViewStoreOf<TimePeriodDetailsFeature>) -> some View {
    switch viewStore.summaryType {
    case .chart(let points, let expectedPoints):
      LinearChartView(points: points, expectedPoints: expectedPoints)
        .frame(height: 200.0)
    case .circle(let progress):
      CircularProgressView(
        progress: progress,
        showPercent: true,
        lineWidth: 20.0
      )
        .frame(height: 200.0)
    }
  }

  // MARK: - Private

  private func name(for timePeriod: TimePeriod) -> String {
    switch timePeriod.type {
    case .day:
      String(localized: "Daily", bundle: .module)
    case .week:
      String(localized: "Weekly", bundle: .module)
    case .month:
      String(localized: "Monthly", bundle: .module)
    case .quarter:
      String(localized: "Quarterly", bundle: .module)
    }
  }
}
