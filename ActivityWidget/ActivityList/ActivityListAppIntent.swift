import WidgetKit
import AppIntents

struct ActivityListAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Configuration"
  static var description = IntentDescription("List of activities widget")

  @Parameter(title: "Hide completed", default: false)
  var hideCompleted: Bool
}
