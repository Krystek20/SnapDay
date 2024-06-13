import SwiftUINavigationCore

extension AlertState {

  static func showAlertSelectAll(
    confirmAction: DayActivityFormFeature.Action.DayActivityAlert,
    cancelAction: DayActivityFormFeature.Action.DayActivityAlert
  ) -> AlertState<DayActivityFormFeature.Action.DayActivityAlert> {
    let title = String(
      localized: "Incomplete Subtasks",
      bundle: .module
    )
    let message = String(
      localized: "This activity has incomplete subtasks. Would you like to mark the activity and all its subtasks as done?",
      bundle: .module
    )
    return AlertState<DayActivityFormFeature.Action.DayActivityAlert>(
      title: TextState(title),
      message: TextState(message),
      buttons: [
        ButtonState(
          action: cancelAction,
          label: { TextState(String(localized: "Mark Activity Only", bundle: .module)) }
        ),
        ButtonState(
          action: confirmAction,
          label: { TextState(String(localized: "Mark All as Done", bundle: .module)) }
        )
      ]
    )
  }

  static func dayActivityTaskAlert(
    confirmAction: DayActivityFormFeature.Action.DayActivityTaskAlert,
    cancelAction: DayActivityFormFeature.Action.DayActivityTaskAlert
  ) -> AlertState<DayActivityFormFeature.Action.DayActivityTaskAlert> {
    let title = String(
      localized: "Complete Activity?",
      bundle: .module
    )
    let message = String(
      localized: "This is the last task for this activity. Would you like to mark the activity as complete?",
      bundle: .module
    )
    return AlertState<DayActivityFormFeature.Action.DayActivityTaskAlert>(
      title: TextState(title),
      message: TextState(message),
      buttons: [
        ButtonState(
          action: cancelAction,
          label: { TextState(String(localized: "Not Yet", bundle: .module)) }
        ),
        ButtonState(
          action: confirmAction,
          label: { TextState(String(localized: "Complete Activity", bundle: .module)) }
        )
      ]
    )
  }
}
