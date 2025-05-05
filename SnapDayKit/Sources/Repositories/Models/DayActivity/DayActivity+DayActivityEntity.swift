import Foundation
import CoreData.NSManagedObjectContext
import Models

extension DayActivity {
  init(_ entity: DayActivityEntity, context: NSManagedObjectContext) throws {
    guard let identifier = entity.identifier,
          let dayActivityTasks = entity.dayActivityTasks?.allObjects as? [DayActivityTaskEntity] else {
      let message = """
        let objectID = \(String(describing: entity.objectID)),
        let identifier = \(String(describing: entity.identifier)),
        let dayActivityTasks = \(String(describing: entity.dayActivityTasks?.allObjects as? [DayActivityTaskEntity]))
      """
      throw EntityError.attributeNil(message: message)
    }

    let activity = try? Activity(
      identifier: entity.templateIdentifier?.uuidString,
      context: context
    )
    let tags: [Tag] = (try? entity.mapIdentifierArray(for: "tagsIdentifiers", context: context)) ?? []
    let labels: [ActivityLabel] = (try? entity.mapIdentifierArray(for: "labelsIdentifiers", context: context)) ?? []

    self.init(
      id: identifier,
      date: entity.date,
      activity: activity,
      name: entity.name ?? "",
      iconId: entity.iconIdentifier,
      dueDate: entity.dueDate,
      doneDate: entity.doneDate,
      duration: Int(entity.duration),
      overview: entity.overview,
      isGeneratedAutomatically: entity.isGeneratedAutomatically,
      tags: tags,
      labels: labels,
      dayActivityTasks: try dayActivityTasks.map {
        try DayActivityTask($0, context: context)
      }.sorted(by: { $0.name < $1.name }),
      reminderDate: entity.reminderDate,
      important: entity.important,
      position: Int(entity.position),
      share: nil
    )
  }
}
