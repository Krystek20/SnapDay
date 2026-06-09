import WidgetKit
import AppIntents

struct WeeklyProgressAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Weekly Progress"
  static var description = IntentDescription("Collect all your activities!")

  @Parameter(
    title: "Filter by activities",
    optionsProvider: ActivityProvider()
  )
  var selectedActivities: [String]?

  @Parameter(title: "Show total activities", default: true)
  var showTotalActivities: Bool

  @Parameter(title: "Show total spent time", default: true)
  var showTotalSpentTime: Bool

  static var parameterSummary: some ParameterSummary {
    Summary("Activities: \(\.$selectedActivities)") {
      \.$showTotalActivities
      \.$showTotalSpentTime
    }
  }
}
