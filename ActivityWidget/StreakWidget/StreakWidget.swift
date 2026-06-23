import WidgetKit
import SwiftUI
import Models
import Utilities
import Repositories
import WidgetStreak
import ComposableArchitecture

struct StreakWidgetProvider: AppIntentTimelineProvider, TodayProvidable {

  private let activityRepository = ActivityRepository.liveValue
  private let streakProvider = StreakProvider()

  func placeholder(in context: Context) -> StreakEntry {
    StreakEntry(
      activity: nil,
      date: Date(),
      streak: nil,
      configuration: StreakAppIntent()
    )
  }

  func snapshot(for configuration: StreakAppIntent, in context: Context) async -> StreakEntry {
    StreakEntry(
      activity: nil,
      date: Date(),
      streak: nil,
      configuration: configuration
    )
  }

  func timeline(for configuration: StreakAppIntent, in context: Context) async -> Timeline<StreakEntry> {
    do {
      var activity: Activity?
      var streak: Streak?

      if let activityName = configuration.activity,
         let fetchedActivity = try await activityRepository.activity(.name(activityName)) {
        activity = fetchedActivity
        streak = try await streakProvider.streak(for: fetchedActivity)
      }

      return Timeline(
        entries: [
          StreakEntry(
            activity: activity,
            date: today,
            streak: streak,
            configuration: configuration
          )
        ],
        policy: .after(try tomorrow)
      )
    } catch {
      return Timeline(
        entries: [
          StreakEntry(
            activity: nil,
            date: Date(),
            streak: nil,
            configuration: configuration
          )
        ],
        policy: .after(Date.now.addingTimeInterval(15 * 60))
      )
    }
  }
}

struct StreakEntry: TimelineEntry {
  let activity: Activity?
  let date: Date
  let streak: Streak?
  let configuration: StreakAppIntent
}

struct StreakEntryView : View {
  var entry: StreakWidgetProvider.Entry

  var body: some View {
    WidgetStreakView(
      store: Store(
        initialState: WidgetStreakFeature.State(
          activity: entry.activity,
          streak: entry.streak
        ),
        reducer: { WidgetStreakFeature() }
      )
    )
  }
}

struct StreakWidget: Widget {
  let kind: String = "ActivityWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: StreakAppIntent.self,
      provider: StreakWidgetProvider()
    ) { entry in
      StreakEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .contentMarginsDisabled()
    .supportedFamilies([.systemSmall])
  }
}
