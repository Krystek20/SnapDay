import Foundation

public enum SnapDayPlusProduct: String, CaseIterable, Codable, Sendable {
  case monthly = "com.mobilove.snapday.plus.monthly"
  case annual = "com.mobilove.snapday.plus.annual"
}

public struct SubscriptionProduct: Equatable, Identifiable, Sendable {
  public let id: String
  public let displayName: String
  public let displayPrice: String
  public let subscriptionPeriod: SubscriptionPeriod
  public let isEligibleForIntroductoryOffer: Bool

  public init(
    id: String,
    displayName: String,
    displayPrice: String,
    subscriptionPeriod: SubscriptionPeriod,
    isEligibleForIntroductoryOffer: Bool
  ) {
    self.id = id
    self.displayName = displayName
    self.displayPrice = displayPrice
    self.subscriptionPeriod = subscriptionPeriod
    self.isEligibleForIntroductoryOffer = isEligibleForIntroductoryOffer
  }
}

public struct SubscriptionPeriod: Equatable, Sendable {
  public enum Unit: Equatable, Sendable {
    case day
    case week
    case month
    case year
  }

  public let value: Int
  public let unit: Unit

  public init(value: Int, unit: Unit) {
    self.value = value
    self.unit = unit
  }
}
