import WidgetKit
import AppIntents
import Models

@available(iOS 17.0, *)
struct StreakAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Activty Streak"
  static var description = IntentDescription("Streak of activity")

  @Parameter(title: "Select Activity", optionsProvider: ActivityProvider())
  var activity: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Track \(\.$activity)")
  }
}
