import Models

extension DayActivity {
  var areAllSubtasksDone: Bool {
    let areAllSubtasksDone = dayActivityTasks.filter { !$0.isDone }.isEmpty
    return doneDate == nil && !areAllSubtasksDone
  }

  func areAllSubtasksDone(exclude dayActivityTask: DayActivityTask) -> Bool {
    let areAllSubtasksDone = dayActivityTasks
      .filter { $0.id != dayActivityTask.id && !$0.isDone }
      .isEmpty
    return dayActivityTask.doneDate == nil && doneDate == nil && areAllSubtasksDone
  }
}
