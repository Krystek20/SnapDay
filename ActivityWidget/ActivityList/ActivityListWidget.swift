import WidgetKit
import SwiftUI
import WidgetActivityList
import ComposableArchitecture
import Models
import Utilities

@available(iOSApplicationExtension 17.0, *)
struct ActivityListProvider: AppIntentTimelineProvider, TodayProvidable {

  private let dayProvider = DayProvider()

  func placeholder(in context: Context) -> DayEntry {
    DayEntry(
      day: nil,
      date: Date(),
      configuration: ActivityListAppIntent()
    )
  }

  func snapshot(for configuration: ActivityListAppIntent, in context: Context) async -> DayEntry {
    DayEntry(
      day: nil,
      date: Date(),
      configuration: configuration
    )
  }

  func timeline(for configuration: ActivityListAppIntent, in context: Context) async -> Timeline<DayEntry> {
    var entries = [DayEntry]()
    let reloadPolicy: TimelineReloadPolicy
    do {
      entries.append(
        DayEntry(
          day: try await dayProvider.day(today), 
          date: today,
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
struct DayEntry: TimelineEntry {
  let day: Day?
  let date: Date
  let configuration: ActivityListAppIntent
}

@available(iOSApplicationExtension 17.0, *)
struct ActivityListWidgetEntryView : View {
  var entry: ActivityListProvider.Entry

  var body: some View {
    WidgetActivityListView(
      store: Store(
        initialState: WidgetActivityListFeature.State(
          day: entry.day,
          hideCompleted: entry.configuration.hideCompleted
        ),
        reducer: { WidgetActivityListFeature() }
      ),
      listUpIntent: { ListUp() },
      listDownIntent: { ListDown() },
      switchItemIntent: { identifier in ToggleItemIntent(identifier: identifier.uuidString) }
    )
  }
}

@available(iOSApplicationExtension 17.0, *)
struct ActivityListWidget: Widget {
  let kind: String = "ActivityListWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ActivityListAppIntent.self, provider: ActivityListProvider()) { entry in
      ActivityListWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .contentMarginsDisabled()
    .supportedFamilies([.systemLarge])
  }
}
