import Foundation
import Models

extension Day {
  init(_ entity: DayEntity) throws {
    guard let id = entity.identifier,
          let date = entity.date,
          let activities = entity.activities?.allObjects as? [DayActivityEntity]  else {
      throw EntityError.attributeNil()
    }
    self.init(
      id: id,
      date: date,
      activities: try activities.map(DayActivity.init)
    )
  }
}
