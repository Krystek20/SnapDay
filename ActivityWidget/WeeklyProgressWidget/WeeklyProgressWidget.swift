import WidgetKit
import SwiftUI
import Models
import Utilities
import Repositories
import WidgetWeeklyProgress
import ComposableArchitecture

struct WeeklyProgressWidgetProvider: AppIntentTimelineProvider, TodayProvidable {

  private let activityRepository = ActivityRepository.liveValue
  private let streakProvider = StreakProvider()

  func placeholder(in context: Context) -> WeeklyProgressEntry {
    .preview()
  }

  func snapshot(for configuration: WeeklyProgressAppIntent, in context: Context) async -> WeeklyProgressEntry {
    guard !context.isPreview else {
      return .preview(configuration: configuration)
    }

    let timeline = await timeline(for: configuration, in: context)
    return timeline.entries.first ?? .preview(configuration: configuration)
  }

  func timeline(for configuration: WeeklyProgressAppIntent, in context: Context) async -> Timeline<WeeklyProgressEntry> {
    @Dependency(\.dayUpdater) var dayUpdater
    let periodDateRangeCreator = PeriodDateRangeCreator()
    guard let range = periodDateRangeCreator.prepareClosedRange(for: .week, periodShift: .zero) else {
      return Timeline(
        entries: [
          WeeklyProgressEntry(
            days: [],
            date: Date(),
            configuration: configuration
          )
        ],
        policy: .after(Date.now.addingTimeInterval(15 * 60))
      )
    }

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
      return Timeline(
        entries: [
          WeeklyProgressEntry(
            days: days,
            date: today,
            configuration: configuration
          )
        ],
        policy: .after(try tomorrow)
      )
    } catch {
      return Timeline(
        entries: [
          WeeklyProgressEntry(
            days: [],
            date: Date(),
            configuration: configuration
          )
        ],
        policy: .after(Date.now.addingTimeInterval(15 * 60))
      )
    }
  }
}

struct WeeklyProgressEntry: TimelineEntry {
  let days: [Day]
  let date: Date
  let configuration: WeeklyProgressAppIntent
}

extension WeeklyProgressEntry {
  static func preview(
    configuration: WeeklyProgressAppIntent = WeeklyProgressAppIntent(),
    referenceDate: Date = .now
  ) -> Self {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = .autoupdatingCurrent
    let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
    let completionByDay = [
      (completed: 2, planned: 2),
      (completed: 1, planned: 2),
      (completed: 3, planned: 3),
      (completed: 0, planned: 2),
      (completed: 1, planned: 1),
      (completed: 0, planned: 0),
      (completed: 1, planned: 2)
    ]

    let days = completionByDay.enumerated().compactMap { offset, progress -> Day? in
      guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
        return nil
      }
      let activities = (0..<progress.planned).map { index in
        DayActivity(
          id: UUID(),
          date: date,
          name: "Activity \(index + 1)",
          doneDate: index < progress.completed ? date : nil,
          duration: 20,
          isGeneratedAutomatically: false
        )
      }
      return Day(id: UUID(), date: date, activities: activities)
    }

    return Self(
      days: days,
      date: referenceDate,
      configuration: configuration
    )
  }
}

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
    .configurationDisplayName("Weekly progress")
    .description("See your activity progress for the week.")
    .contentMarginsDisabled()
    .supportedFamilies([.systemMedium])
  }
}

#Preview("Weekly progress", as: .systemMedium) {
  WeeklyProgressWidget()
} timeline: {
  WeeklyProgressEntry.preview()
}
