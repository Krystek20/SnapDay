import Foundation
import Models

extension DayActivity {
  init(_ entity: DayActivityEntity) throws {
    guard let identifier = entity.identifier,
          let activityEntity = entity.activity,
          let tags = entity.tags?.allObjects as? [TagEntity],
          let labels = entity.labels?.allObjects as? [ActivityLabelEntity],
          let dayActivityTasks = entity.dayActivityTasks?.allObjects as? [DayActivityTaskEntity] else {
      throw EntityError.attributeNil()
    }
    let activity = try Activity(activityEntity)
    self.init(
      id: identifier,
      activity: activity,
      name: entity.name ?? activity.name,
      icon: try entity.icon.map(Icon.init),
      doneDate: entity.doneDate,
      duration: Int(entity.duration),
      overview: entity.overview,
      isGeneratedAutomatically: entity.isGeneratedAutomatically,
      tags: try tags.map(Tag.init),
      labels: try labels.map(ActivityLabel.init),
      dayActivityTasks: try dayActivityTasks.map(DayActivityTask.init)
        .sorted(by: { $0.name < $1.name })
    )
  }
}
