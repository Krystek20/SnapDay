import Foundation
import Models

extension SharedDayActivityTask {
  public mutating func merge(_ sharedDayActivityTask: SharedDayActivityTask) {
    name = nameLastUpdated.orPast > sharedDayActivityTask.nameLastUpdated.orPast ? name : sharedDayActivityTask.name
    nameLastUpdated = nameLastUpdated.orPast > sharedDayActivityTask.nameLastUpdated.orPast ? nameLastUpdated : sharedDayActivityTask.nameLastUpdated
    doneDate = doneDateLastUpdated.orPast > sharedDayActivityTask.doneDateLastUpdated.orPast ? doneDate : sharedDayActivityTask.doneDate
    sharedBy = sharedDayActivityTask.sharedBy
  }
}
