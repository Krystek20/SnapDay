import Foundation
import Models

extension SharedDayActivity {
  public mutating func merge(_ sharedDayActivity: SharedDayActivity) {
    date = dateLastUpdated.orPast > sharedDayActivity.dateLastUpdated.orPast ? date : sharedDayActivity.date
    dateLastUpdated = dateLastUpdated.orPast > sharedDayActivity.dateLastUpdated.orPast ? dateLastUpdated : sharedDayActivity.dateLastUpdated
    name = nameLastUpdated.orPast > sharedDayActivity.nameLastUpdated.orPast ? name : sharedDayActivity.name
    nameLastUpdated = nameLastUpdated.orPast > sharedDayActivity.nameLastUpdated.orPast ? nameLastUpdated : sharedDayActivity.nameLastUpdated
    iconId = iconIdLastUpdated.orPast > sharedDayActivity.iconIdLastUpdated.orPast ? iconId : sharedDayActivity.iconId
    iconIdLastUpdated = iconIdLastUpdated.orPast > sharedDayActivity.iconIdLastUpdated.orPast ? iconIdLastUpdated : sharedDayActivity.iconIdLastUpdated
    dueDate = dueDateLastUpdated.orPast > sharedDayActivity.dueDateLastUpdated.orPast ? dueDate : sharedDayActivity.dueDate
    dueDateLastUpdated = dueDateLastUpdated.orPast > sharedDayActivity.dueDateLastUpdated.orPast ? dueDateLastUpdated : sharedDayActivity.dueDateLastUpdated
    important = importantLastUpdated.orPast > sharedDayActivity.importantLastUpdated.orPast ? important : sharedDayActivity.important
    importantLastUpdated = importantLastUpdated.orPast > sharedDayActivity.importantLastUpdated.orPast ? importantLastUpdated : sharedDayActivity.importantLastUpdated
    doneDate = doneDateLastUpdated.orPast > sharedDayActivity.doneDateLastUpdated.orPast ? doneDate : sharedDayActivity.doneDate
    doneByUserId = doneDateLastUpdated.orPast > sharedDayActivity.doneDateLastUpdated.orPast ? doneByUserId : sharedDayActivity.doneByUserId
    doneDateLastUpdated = doneDateLastUpdated.orPast > sharedDayActivity.doneDateLastUpdated.orPast ? doneDateLastUpdated : sharedDayActivity.doneDateLastUpdated
    sharedBy = sharedDayActivity.sharedBy
    tasks = sharedDayActivity.tasks
  }
}
