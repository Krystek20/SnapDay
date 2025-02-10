import Models
import CoreData

extension ActivityLabelEntity {
  func setup(by activityLabel: ActivityLabel) {
    identifier = activityLabel.id
    name = activityLabel.name
    colorIdentifier = activityLabel.rgbColor.id
  }
}
