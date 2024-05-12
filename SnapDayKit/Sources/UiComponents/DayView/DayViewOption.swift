import Models

public enum DayViewOption {
  case simple(DayViewSimpleActions)
  case all(DayViewAllActions)
}

public struct DayViewSimpleActions {
  
  let activityTapped: (DayActivity) -> Void
  let activityTaskTapped: (DayActivity, DayActivityTask) -> Void

  public init(
    activityTapped: @escaping (DayActivity) -> Void,
    activityTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void
  ) {
    self.activityTapped = activityTapped
    self.activityTaskTapped = activityTaskTapped
  }
}

public struct DayViewAllActions {
  
  let activityTapped: (DayActivity) -> Void
  let editTapped: (DayActivity) -> Void
  let removeTapped: (DayActivity) -> Void
  let activityTaskTapped: (DayActivity, DayActivityTask) -> Void
  let editTaskTapped: (DayActivity, DayActivityTask) -> Void
  let removeTaskTapped: (DayActivityTask) -> Void

  public init(
    activityTapped: @escaping (DayActivity) -> Void,
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void,
    activityTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    editTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    removeTaskTapped: @escaping (DayActivityTask) -> Void
  ) {
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
    self.activityTaskTapped = activityTaskTapped
    self.editTaskTapped = editTaskTapped
    self.removeTaskTapped = removeTaskTapped
  }
}
