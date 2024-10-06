import Models
import struct UiComponents.ComplateAlertViewConfiguration

struct DashboardAlert: Equatable {
  let type: DashboardAlertType
  let configuration: ComplateAlertViewConfiguration
}

enum DashboardAlertType: Equatable {
  case incompleteSubtasks(dayActivity: DayActivity)
  case completeActivity(dayActivity: DayActivity)
}
