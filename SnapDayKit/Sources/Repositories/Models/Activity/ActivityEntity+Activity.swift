import Foundation
import Models

extension ActivityEntity {
  func setup(by activity: Activity) throws {
    identifier = activity.id
    name = activity.name
    image = activity.image
    if let frequency = activity.frequency {
      frequencyJson = try JSONEncoder().encode(frequency)
    } else {
      frequencyJson = nil
    }
    isDefaultDuration = activity.defaultDuration != nil
    defaultDuration = Int32(activity.defaultDuration ?? .zero)
    isVisible = activity.isVisible
    startDate = activity.startDate
  }
}
