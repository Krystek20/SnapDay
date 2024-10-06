import Foundation
import SwiftUI

public enum Images: String {
  case listEmpty = "list_empty"
  case listDone = "list_done"
  case activityListEmpty = "activity_list_empty"
  case onboardingWelcome = "onboarding_welcome"
  case onboardingFeatureHabitTracking = "onboarding_feature_habit_tracking"
  case onboardingFeatureTakeControl = "onboarding_feature_take_control"
  case onboardingFeatureAchieveGoals = "onboarding_feature_achieve_goals"
  case onboardingIcloud = "onboarding_icloud"
  case onboardingFeatureNotifications = "onboarding_feature_notifications"
  case incompleteIcon = "incomplete_icon"
}

public extension Image {
  init(from images: Images) {
    self.init(images.rawValue, bundle: .module)
  }
}
