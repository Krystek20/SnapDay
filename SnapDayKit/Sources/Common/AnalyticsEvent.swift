public struct AnalyticsEvent: Equatable, Sendable {
  public let name: String
  public let parameters: [String: String]

  public init(name: String, parameters: [String: String] = [:]) {
    self.name = name
    self.parameters = parameters
  }
}

public extension AnalyticsEvent {
  static let onboardingCompleted = Self(name: "Onboarding.completed")
  static let planCreated = Self(name: "Plan.created")

  static func paywallViewed(context: String) -> Self {
    Self(name: "Paywall.viewed", parameters: ["context": context])
  }

  static func subscriptionPurchased(
    productID: String,
    context: String
  ) -> Self {
    Self(
      name: "Subscription.purchased",
      parameters: [
        "productID": productID,
        "context": context
      ]
    )
  }
}
