import Models

enum ReportDayActivity: Equatable {
  case tag(ReportDayState, RGBColor)
  case activity(ReportDayState, Icon?)
  case empty
}
