import WidgetKit
import AppIntents

@available(iOS 17.0, *)
struct ActivityListAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Configuration"
  static var description = IntentDescription("List of activities widget")

  @Parameter(title: "Hide completed", default: false)
  var hideCompleted: Bool
}
