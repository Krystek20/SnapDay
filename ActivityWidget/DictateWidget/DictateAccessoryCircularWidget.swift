import WidgetKit
import SwiftUI
import Utilities

struct DictateWidgetEntry: TimelineEntry {
  let date = Date()
}

struct DictateWidgetProvider: TimelineProvider {
  func getSnapshot(in context: Context, completion: @escaping @Sendable (DictateWidgetEntry) -> Void) {
    completion(DictateWidgetEntry())
  }

  func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<DictateWidgetEntry>) -> Void) {
    completion(Timeline(entries: [DictateWidgetEntry()], policy: .never))
  }

  func placeholder(in context: Context) -> DictateWidgetEntry {
    DictateWidgetEntry()
  }
}

struct DictateAccessoryCircularView: View {
  var entry: DictateWidgetEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()

      Link(destination: DeeplinkService.dictate, label: {
        Image(systemName: "mic.fill")
          .font(.system(size: 20))
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .red)
          .accessibilityLabel("Dictate goal")
      })
    }
    .widgetURL(DeeplinkService.dictate)
  }
}

struct DictateAccessoryCircularWidget: Widget {
  let kind = "DictateAccessoryCircularWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DictateWidgetProvider()) { entry in
      DictateAccessoryCircularView(entry: entry)
    }
    .configurationDisplayName("Dictate Goal")
    .description("Quickly dictate your daily goal.")
    .supportedFamilies([.accessoryCircular])
  }
}
