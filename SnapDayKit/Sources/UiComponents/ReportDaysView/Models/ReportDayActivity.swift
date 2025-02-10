import Models
import Foundation

enum ReportDayActivity: Equatable {
  case tag(ReportDayState, RGBColor)
  case activity(ReportDayState, UUID?)
  case empty
}
