import WidgetKit
import SwiftUI
import Models
import Utilities
import Repositories
import WidgetWeeklyProgress
import ComposableArchitecture

@available(iOSApplicationExtension 17.0, *)
struct WeeklyProgressWidgetProvider: AppIntentTimelineProvider, TodayProvidable {

  private let activityRepository = ActivityRepository.liveValue
  private let streakProvider = StreakProvider()

  func placeholder(in context: Context) -> WeeklyProgressEntry {
    WeeklyProgressEntry(
      days: [],
      date: Date(),
      configuration: WeeklyProgressAppIntent()
    )
  }

  func snapshot(for configuration: WeeklyProgressAppIntent, in context: Context) async -> WeeklyProgressEntry {
    WeeklyProgressEntry(
      days: [],
      date: Date(),
      configuration: configuration
    )
  }

  func timeline(for configuration: WeeklyProgressAppIntent, in context: Context) async -> Timeline<WeeklyProgressEntry> {
    @Dependency(\.dayUpdater) var dayUpdater
    let periodDateRangeCreator = PeriodDateRangeCreator()
    guard let range = periodDateRangeCreator.prepareClosedRange(for: .week, periodShift: .zero) else {
      return Timeline(entries: [], policy: .never)
    }
    var entries = [WeeklyProgressEntry]()
    let reloadPolicy: TimelineReloadPolicy

    do {
      let days: [Day]
      if let selectedActivities = configuration.selectedActivities,
         !selectedActivities.isEmpty {
        let filteredActivities = try await activityRepository.loadActivities()
          .filter { selectedActivities.contains($0.name) }
        let daysToFilter = try await dayUpdater.days(for: range)
        days = daysToFilter.map { day in
          var updatedDay = day
          updatedDay.activities = day.activities.filter { activity in
            filteredActivities.contains(where: { $0.id == activity.activity?.id })
          }
          return updatedDay
        }
      } else {
        days = try await dayUpdater.days(for: range)
      }
      entries.append(
        WeeklyProgressEntry(
          days: days,
          date: today,
          configuration: configuration
        )
      )
      reloadPolicy = .after(try tomorrow)
    } catch {
      reloadPolicy = .never
    }

    return Timeline(entries: entries, policy: reloadPolicy)
  }
}

@available(iOSApplicationExtension 17.0, *)
struct WeeklyProgressEntry: TimelineEntry {
  let days: [Day]
  let date: Date
  let configuration: WeeklyProgressAppIntent
}

@available(iOS 17.0, *)
struct WeeklyProgressEntryView : View {
  var entry: WeeklyProgressWidgetProvider.Entry

  var body: some View {
    WeeklyProgressView(
      store: Store(
        initialState: WeeklyProgressFeature.State(
          days: entry.days,
          showTotalActivities: entry.configuration.showTotalActivities,
          showTotalSpentTime: entry.configuration.showTotalSpentTime
        ),
        reducer: { WeeklyProgressFeature() }
      )
    )
  }
}

@available(iOS 17.0, *)
struct WeeklyProgressWidget: Widget {
  let kind: String = "WeeklyProgressWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: WeeklyProgressAppIntent.self,
      provider: WeeklyProgressWidgetProvider()
    ) { entry in
      WeeklyProgressEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .contentMarginsDisabled()
    .supportedFamilies([.systemMedium])
  }
}
