import WidgetKit
import AppIntents

struct ActivityListAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Today's activities"
  static var description = IntentDescription("View and complete today's activities.")

  @Parameter(title: "Hide completed activities", default: false)
  var hideCompleted: Bool
}
