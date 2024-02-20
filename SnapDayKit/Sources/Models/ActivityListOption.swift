import Foundation

public enum ActivityListOption: Equatable {
  case collapsed(doneCount: Int, totalCount: Int, percent: Double)
  case extended
}
