import Foundation

public enum ActivityState: Equatable {
  case toDo
  case completed(startDate: Date, endDate: Date)
}
