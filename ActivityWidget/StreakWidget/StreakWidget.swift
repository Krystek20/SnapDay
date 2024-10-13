import WidgetKit
import SwiftUI
import Models
import Utilities
import Repositories
import WidgetStreak
import ComposableArchitecture

@available(iOSApplicationExtension 17.0, *)
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
    var entries = [StreakEntry]()
    let reloadPolicy: TimelineReloadPolicy

    do {
      var activity: Activity?
      var streak: Streak?

      if let activityName = configuration.activity,
         let fetchedActivity = try await activityRepository.activity(.name(activityName)) {
        activity = fetchedActivity
        streak = try await streakProvider.streak(for: fetchedActivity)
      }

      entries.append(
        StreakEntry(
          activity: activity,
          date: today,
          streak: streak,
          configuration: configuration
        )
      )

      reloadPolicy = .after(try tomorrow)
    } catch {
      reloadPolicy = .never
      print(error.localizedDescription)
    }
    return Timeline(entries: entries, policy: reloadPolicy)
  }
}

@available(iOSApplicationExtension 17.0, *)
struct StreakEntry: TimelineEntry {
  let activity: Activity?
  let date: Date
  let streak: Streak?
  let configuration: StreakAppIntent
}

@available(iOS 17.0, *)
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

@available(iOSApplicationExtension 17.0, *)
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
