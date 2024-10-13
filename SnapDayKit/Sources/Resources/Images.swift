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
  case strike0 = "strike_0"
  case strike1_3 = "strike_1_3"
  case strike4_7 = "strike_4_7"
  case strike8_14 = "strike_8_14"
  case strike15_30 = "strike_15_30"
  case strike31 = "strike_31"
}

public extension Image {
  init(from images: Images) {
    self.init(images.rawValue, bundle: .module)
  }
}
