@testable import Common
import Testing

struct AnalyticsEventTests {
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
