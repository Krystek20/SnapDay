import Foundation

public enum PaywallEntryContext: String, Equatable, Sendable {
  case secondActivePlan
  case advancedRecurrence
  case extendedReports
  case aiAllowanceExhausted
  case planProgressWidget
  case weeklyProgressWidget
  case collaborationInvitation
  case settings

  var title: String {
    switch self {
    case .secondActivePlan:
      String(localized: "Build every routine", bundle: .module)
    case .advancedRecurrence:
      String(localized: "Make your schedule fit real life", bundle: .module)
    case .extendedReports:
      String(localized: "See the patterns behind your progress", bundle: .module)
    case .aiAllowanceExhausted:
      String(localized: "Keep planning with SnapDay AI", bundle: .module)
    case .planProgressWidget:
      String(localized: "Keep your Plan in sight", bundle: .module)
    case .weeklyProgressWidget:
      String(localized: "Keep your week in sight", bundle: .module)
    case .collaborationInvitation:
      String(localized: "Make progress together", bundle: .module)
    case .settings:
      String(localized: "Stay consistent across every routine", bundle: .module)
    }
  }

  var message: String {
    switch self {
    case .secondActivePlan:
      String(localized: "Create more active Plans without giving up the routines already working for you.", bundle: .module)
    case .advancedRecurrence:
      String(localized: "Use flexible recurrence rules for routines that do not fit a simple weekly schedule.", bundle: .module)
    case .extendedReports:
      String(localized: "Explore more of your history and understand how your routines change over time.", bundle: .module)
    case .aiAllowanceExhausted:
      String(localized: "Continue using AI assistance after your free allowance has been used.", bundle: .module)
    case .planProgressWidget:
      String(localized: "Follow a specific Plan from your Home Screen and see progress at a glance.", bundle: .module)
    case .weeklyProgressWidget:
      String(localized: "Follow your weekly progress from your Home Screen and see the week at a glance.", bundle: .module)
    case .collaborationInvitation:
      String(localized: "Invite others and manage the people sharing your routines.", bundle: .module)
    case .settings:
      String(localized: "Build more Plans and see what helps you keep going.", bundle: .module)
    }
  }
}
