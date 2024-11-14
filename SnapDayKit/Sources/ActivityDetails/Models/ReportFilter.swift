import Foundation
import Models

enum ReportFilter: Equatable {
  case activityLabel(ActivityLabel?)
  case activity(Activity?)
  case none
}
