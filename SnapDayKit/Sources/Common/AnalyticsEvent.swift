public struct AnalyticsEvent: Equatable, Sendable {
  public let name: String
  public let parameters: [String: String]

  public init(name: String, parameters: [String: String] = [:]) {
    self.name = name
    self.parameters = parameters
  }
}

public extension AnalyticsEvent {
  static func onboardingCompleted(outcome: String) -> Self {
    Self(name: "Onboarding.completed", parameters: ["outcome": outcome])
  }

  static func planCreationStarted(source: String) -> Self {
    Self(name: "Plan.creationStarted", parameters: ["source": source])
  }

  static func planCreated(
    source: String,
    duration: String,
    plannedActivityCount: Int
  ) -> Self {
    Self(
      name: "Plan.created",
      parameters: [
        "source": source,
        "duration": duration,
        "plannedActivityCount": String(plannedActivityCount)
      ]
    )
  }

  static func premiumAccessRequested(context: String, hasAccess: Bool) -> Self {
    Self(
      name: "Premium.accessRequested",
      parameters: [
        "context": context,
        "hasAccess": String(hasAccess)
      ]
    )
  }

  static func paywallViewed(context: String) -> Self {
    Self(name: "Paywall.viewed", parameters: ["context": context])
  }

  static func paywallDismissed(context: String) -> Self {
    Self(name: "Paywall.dismissed", parameters: ["context": context])
  }

  static func subscriptionProductSelected(productID: String, context: String) -> Self {
    subscriptionEvent(
      named: "Subscription.productSelected",
      productID: productID,
      context: context
    )
  }

  static func subscriptionPurchaseStarted(productID: String, context: String) -> Self {
    subscriptionEvent(
      named: "Subscription.purchaseStarted",
      productID: productID,
      context: context
    )
  }

  static func subscriptionPurchaseFinished(
    outcome: String,
    productID: String,
    context: String
  ) -> Self {
    Self(
      name: "Subscription.purchaseFinished",
      parameters: [
        "outcome": outcome,
        "productID": productID,
        "context": context
      ]
    )
  }

  static func subscriptionRestoreFinished(outcome: String, context: String) -> Self {
    Self(
      name: "Subscription.restoreFinished",
      parameters: [
        "outcome": outcome,
        "context": context
      ]
    )
  }

  private static func subscriptionEvent(
    named name: String,
    productID: String,
    context: String
  ) -> Self {
    Self(
      name: name,
      parameters: [
        "productID": productID,
        "context": context
      ]
    )
  }
}
