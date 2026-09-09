@testable import Common
import Testing

struct AnalyticsEventTests {
  @Test
  func planCreatedContainsAggregateMetadata() {
    let event = AnalyticsEvent.planCreated(
      source: "plans",
      duration: "custom",
      plannedActivityCount: 21
    )

    #expect(event.name == "Plan.created")
    #expect(
      event.parameters == [
        "source": "plans",
        "duration": "custom",
        "plannedActivityCount": "21"
      ]
    )
  }

  @Test
  func purchaseFinishedContainsFunnelContext() {
    let event = AnalyticsEvent.subscriptionPurchaseFinished(
      outcome: "purchased",
      productID: "snapday.plus.annual",
      context: "settings"
    )

    #expect(event.name == "Subscription.purchaseFinished")
    #expect(
      event.parameters == [
        "outcome": "purchased",
        "productID": "snapday.plus.annual",
        "context": "settings"
      ]
    )
  }
}
