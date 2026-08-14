import Foundation

struct OnboardingTemplate: Equatable, Identifiable, Sendable {
  let icon: String
  let title: String
  let subtitle: String
  let activityTitle: String
  let cadence: OnboardingPlanRequest.Cadence

  var id: String { title }

  var planRequest: OnboardingPlanRequest {
    OnboardingPlanRequest(
      name: title,
      activityTitle: activityTitle,
      cadence: cadence
    )
  }
}
