import Foundation

public enum PremiumEntitlement: Codable, Equatable, Sendable {
  case unknown
  case free
  case trial(expirationDate: Date?)
  case subscribed(expirationDate: Date?)
  case gracePeriod(expirationDate: Date?)
  case billingRetry(expirationDate: Date?)
  case expired(expirationDate: Date?)
  case revoked(revocationDate: Date?)

  public var hasAccess: Bool {
    switch self {
    case .trial, .subscribed, .gracePeriod:
      true
    case .unknown, .free, .billingRetry, .expired, .revoked:
      false
    }
  }
}

public enum PurchaseOutcome: Equatable, Sendable {
  case purchased(PremiumEntitlement)
  case pending
  case cancelled
}

public enum RestoreOutcome: Equatable, Sendable {
  case restored(PremiumEntitlement)
  case noActiveEntitlement
}

public enum PaymentError: Error, Equatable, Sendable {
  case productUnavailable
  case unverifiedTransaction
  case unexpectedTransaction
  case entitlementUnavailable
  case unknownPurchaseResult
}

extension PremiumEntitlement {
  var restoreOutcome: RestoreOutcome {
    hasAccess ? .restored(self) : .noActiveEntitlement
  }
}
