import Models
import CoreData

extension ActivityLabelEntity {
  func setup(by activityLabel: ActivityLabel, context: NSManagedObjectContext) throws {
    identifier = activityLabel.id
    name = activityLabel.name
    color = try activityLabel.rgbColor.managedObject(context)
  }
}
