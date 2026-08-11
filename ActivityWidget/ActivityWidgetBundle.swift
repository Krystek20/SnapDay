import WidgetKit
import SwiftUI

@main
struct ActivityWidgetBundle: WidgetBundle {
  var body: some Widget {
    ActivityListWidget()
    StreakWidget()
    WeeklyProgressWidget()
    PlanProgressWidget()
    #if DEBUG
    DictateAccessoryCircularWidget()
    #endif
  }
}
