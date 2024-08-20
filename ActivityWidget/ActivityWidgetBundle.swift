import WidgetKit
import SwiftUI

@main
struct ActivityWidgetBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOSApplicationExtension 17.0, *) {
      ActivityWidget()
      ActivityWidgetLiveActivity()
    }
  }
}
