import Foundation

public enum DayNewActivityAction: Equatable {

  public enum DayActivity: Equatable {
    case cancelled
    case submitted
  }

  public enum DayActivityTask {
    case cancelled
    case submitted
  }

  case dayActivity(DayActivity)
  case dayActivityTask(DayActivityTask)
}
