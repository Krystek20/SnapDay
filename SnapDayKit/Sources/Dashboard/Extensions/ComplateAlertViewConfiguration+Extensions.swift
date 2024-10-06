import SwiftUINavigationCore
import struct UiComponents.ComplateAlertViewConfiguration

extension ComplateAlertViewConfiguration {
  static var incompleteSubtasks: ComplateAlertViewConfiguration {
    ComplateAlertViewConfiguration(
      image: .incompleteIcon,
      title: String(localized: "Incomplete Subtasks", bundle: .module),
      subtitle: String(localized: "This activity has incomplete subtasks. Would you like to mark the activity and all its subtasks as done?", bundle: .module),
      confirmButtonTitle: String(localized: "Confirm", bundle: .module),
      cancelButtonTitle: String(localized: "Cancel", bundle: .module),
      remainingTime: 5.0
    )
  }

  static var completeActivity: ComplateAlertViewConfiguration {
    ComplateAlertViewConfiguration(
      image: .incompleteIcon,
      title: String(localized: "Complete Activity?", bundle: .module),
      subtitle: String(localized: "This is the last task for this activity. Would you like to mark the activity as complete?", bundle: .module),
      confirmButtonTitle: String(localized: "Confirm", bundle: .module),
      cancelButtonTitle: String(localized: "Cancel", bundle: .module),
      remainingTime: 5.0
    )
  }
}
