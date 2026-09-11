@testable import Common
import Testing

struct AnalyticsEventTests {
  @Test
  func onboardingOutcomeEventsAreDistinct() {
    #expect(AnalyticsEvent.onboardingCompleted.name == "Onboarding.completed")
    #expect(AnalyticsEvent.onboardingSkipped.name == "Onboarding.skipped")
  }

  @Test
  func planCreatedDoesNotContainBehavioralMetadata() {
    #expect(AnalyticsEvent.planCreated.name == "Plan.created")
    #expect(AnalyticsEvent.planCreated.parameters.isEmpty)
  }

  @Test
  func subscriptionPurchasedContainsFunnelContext() {
    let event = AnalyticsEvent.subscriptionPurchased(
      productID: "snapday.plus.annual",
      context: "settings"
    )

    #expect(event.name == "Subscription.purchased")
    #expect(
      event.parameters == [
        "productID": "snapday.plus.annual",
        "context": "settings"
      ]
    )
  }
}
