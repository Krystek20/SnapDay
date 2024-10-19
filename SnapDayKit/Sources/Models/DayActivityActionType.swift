import Foundation

public enum DayActivityActionType: Equatable {

  public enum DayActivityAction: Equatable {
    case tapped
    case edit
    case copy
    case move
    case remove
    case addActivityTask
    case save
    case reorder(ReorderAction)
    case markImportant
    case unmarkImportant
  }

  public enum DayActivityTaskAction: Equatable {
    case tapped
    case edit
    case remove
  }

  public enum ReorderAction: Equatable {
    case perform(destination: DayActivity)
    case drop
  }

  case dayActivity(DayActivityAction, DayActivity)
  case dayActivityTask(DayActivityTaskAction, DayActivityTask)
}
