import Foundation
import Models

extension DayActivity {
  init(_ entity: DayActivityEntity) throws {
    guard let identifier = entity.identifier,
          let dayId = entity.day?.identifier,
          let tags = entity.tags?.allObjects as? [TagEntity],
          let labels = entity.labels?.allObjects as? [ActivityLabelEntity],
          let dayActivityTasks = entity.dayActivityTasks?.allObjects as? [DayActivityTaskEntity] else {
      let message = """
        let identifier = \(String(describing: entity.identifier)),
        let dayId = \(String(describing: entity.day?.identifier)),
        let tags = \(String(describing: entity.tags?.allObjects as? [TagEntity])),
        let labels = \(String(describing: entity.labels?.allObjects as? [ActivityLabelEntity])),
        let dayActivityTasks = \(String(describing: entity.dayActivityTasks?.allObjects as? [DayActivityTaskEntity]))
      """
      throw EntityError.attributeNil(message: message)
    }
    self.init(
      id: identifier,
      dayId: dayId,
      activity: try entity.activity.map(Activity.init),
      name: entity.name ?? "",
      icon: try entity.icon.map(Icon.init),
      dueDate: entity.dueDate,
      doneDate: entity.doneDate,
      duration: Int(entity.duration),
      overview: entity.overview,
      isGeneratedAutomatically: entity.isGeneratedAutomatically,
      tags: try tags.map(Tag.init),
      labels: try labels.map(ActivityLabel.init),
      dayActivityTasks: try dayActivityTasks.map(DayActivityTask.init)
        .sorted(by: { $0.name < $1.name }),
      reminderDate: entity.reminderDate,
      important: entity.important,
      position: Int(entity.position)
    )
  }
}
