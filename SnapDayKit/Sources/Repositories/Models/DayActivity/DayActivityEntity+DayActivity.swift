import Foundation
import Models
import CoreData

extension DayActivityEntity {
  func setup(by dayActivity: DayActivity, context: NSManagedObjectContext) throws {
    identifier = dayActivity.id
    duration = Int32(dayActivity.duration)
    overview = dayActivity.overview
    isGeneratedAutomatically = dayActivity.isGeneratedAutomatically
    doneDate = dayActivity.doneDate
    activity = try ActivityEntity.object(
      identifier: dayActivity.activity.id.uuidString,
      fetchRequest: Activity.fetchRequest,
      context: context
    )
    tags = Set(
      try dayActivity.tags.map { tag in
        try tag.managedObject(context)
      }
    ) as NSSet
    labels = Set(
      try dayActivity.labels.map { label in
        try label.managedObject(context)
      }
    ) as NSSet
  }
}
