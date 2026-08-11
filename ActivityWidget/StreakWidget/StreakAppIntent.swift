import WidgetKit
import AppIntents
import Models

struct StreakAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Activity streak"
  static var description = IntentDescription("Track the streak for a saved activity.")

  @Parameter(title: "Activity", optionsProvider: ActivityProvider())
  var activity: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Track \(\.$activity)")
  }
}
