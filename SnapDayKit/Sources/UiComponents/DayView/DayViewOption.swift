import Models

public enum DayViewOption {
  case all(DayViewAllActions)
}

public struct DayViewSimpleActions {
  
  let activityTapped: (DayActivity) -> Void
  let activityTaskTapped: (DayActivityTask) -> Void

  public init(
    activityTapped: @escaping (DayActivity) -> Void,
    activityTaskTapped: @escaping (DayActivityTask) -> Void
  ) {
    self.activityTapped = activityTapped
    self.activityTaskTapped = activityTaskTapped
  }
}

public struct DayViewAllActions {
  
  let activityTapped: (DayActivity) -> Void
  let editTapped: (DayActivity) -> Void
  let removeTapped: (DayActivity) -> Void
  let addNewActivityTask: (DayActivity) -> Void
  let activityTaskTapped: (DayActivityTask) -> Void
  let editTaskTapped: (DayActivityTask) -> Void
  let removeTaskTapped: (DayActivityTask) -> Void

  public init(
    activityTapped: @escaping (DayActivity) -> Void,
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void,
    addNewActivityTask: @escaping (DayActivity) -> Void,
    activityTaskTapped: @escaping (DayActivityTask) -> Void,
    editTaskTapped: @escaping (DayActivityTask) -> Void,
    removeTaskTapped: @escaping (DayActivityTask) -> Void
  ) {
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
    self.addNewActivityTask = addNewActivityTask
    self.activityTaskTapped = activityTaskTapped
    self.editTaskTapped = editTaskTapped
    self.removeTaskTapped = removeTaskTapped
  }
}
