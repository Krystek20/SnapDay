import Foundation

public struct TagActivitySection: Identifiable, Equatable {
  public var id: String { tag.name }
  public let tag: Tag
  public var timePeriodActivities: [TimePeriodActivity]

  public init(tag: Tag, timePeriodActivities: [TimePeriodActivity]) {
    self.tag = tag
    self.timePeriodActivities = timePeriodActivities
  }
}
