import Foundation
import Models

extension DayActivity {
  init?(_ entity: DayActivityEntity) throws {
    guard let identifier = entity.identifier,
          let activityEntity = entity.activity,
          let activity = try Activity(activityEntity) else { return nil }
    self.init(
      id: identifier,
      activity: activity,
      isDone: entity.isDone,
      duration: Int(entity.duration),
      overview: entity.overview,
      isGeneratedAutomatically: entity.isGeneratedAutomatically
    )
  }
}
