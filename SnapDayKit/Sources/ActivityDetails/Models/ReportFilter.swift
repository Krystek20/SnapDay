import Foundation
import Models

public enum ReportFilter: Equatable {
  case activityLabel(ActivityLabel?)
  case activity(Activity?)
  case empty
}
