import WidgetKit
import AppIntents

@available(iOSApplicationExtension 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Configuration"
  static var description = IntentDescription("List of activities widget")

  @Parameter(title: "Hide completed", default: false)
  var hideCompleted: Bool
}
