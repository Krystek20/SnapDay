import WidgetKit
import SwiftUI

@main
struct ActivityWidgetBundle: WidgetBundle {
  var body: some Widget {
    ActivityListWidget()
    StreakWidget()
    WeeklyProgressWidget()
    DictateAccessoryCircularWidget()
  }
}
