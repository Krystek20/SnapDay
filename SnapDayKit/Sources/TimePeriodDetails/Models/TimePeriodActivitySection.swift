import Foundation
import Models

struct TimePeriodActivitySection: Identifiable, Equatable {
  var id: String { tag.name }
  let tag: Tag
  var timePeriodActivities: [TimePeriodActivity]
}
