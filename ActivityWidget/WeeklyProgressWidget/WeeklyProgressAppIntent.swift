import WidgetKit
import AppIntents

struct WeeklyProgressAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Weekly progress · Plus"
  static var description = IntentDescription("Configure weekly progress with SnapDay Plus.")

  @Parameter(
    title: "Activities",
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
