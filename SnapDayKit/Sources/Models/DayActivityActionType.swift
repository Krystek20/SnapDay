import Foundation

public enum DayActivityActionType: Equatable {

  public enum DayActivityAction: Equatable {
    case tapped
    case edit
    case copy
    case move
    case remove
    case addActivityTask
  }

  public enum DayActivityTaskAction: Equatable {
    case tapped
    case edit
    case remove
  }

  case dayActivity(DayActivityAction, DayActivity)
  case dayActivityTask(DayActivityTaskAction, DayActivityTask)
}
