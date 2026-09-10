import Foundation
@testable import Payment
import StoreKit
import Testing

struct PremiumEntitlementTests {
  @Test
  func activeEntitlementWinsOverExpiredCandidate() {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)

    let entitlement = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .expired,
          expirationDate: Date(timeIntervalSince1970: 1_700_000_000),
          revocationDate: nil,
          isIntroductoryOffer: false
        ),
        EntitlementCandidate(
          productID: SnapDayPlusProduct.annual.rawValue,
          state: .subscribed,
          expirationDate: expirationDate,
          revocationDate: nil,
          isIntroductoryOffer: false
        )
      ]
    )

    #expect(entitlement == .subscribed(expirationDate: expirationDate))
    #expect(entitlement.hasAccess)
  }

  @Test
  func introductorySubscriptionMapsToTrial() {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)

    let entitlement = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .subscribed,
          expirationDate: expirationDate,
          revocationDate: nil,
          isIntroductoryOffer: true
        )
      ]
    )

    #expect(entitlement == .trial(expirationDate: expirationDate))
  }

  @Test
  func gracePeriodKeepsPremiumAccess() {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)

    let entitlement = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .inGracePeriod,
          expirationDate: expirationDate,
          revocationDate: nil,
          isIntroductoryOffer: false
        )
      ]
    )

    #expect(entitlement == .gracePeriod(expirationDate: expirationDate))
    #expect(entitlement.hasAccess)
  }

  @Test
  func billingRetryDoesNotKeepPremiumAccess() {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)

    let entitlement = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .inBillingRetryPeriod,
          expirationDate: expirationDate,
          revocationDate: nil,
          isIntroductoryOffer: false
        )
      ]
    )

    #expect(entitlement == .billingRetry(expirationDate: expirationDate))
    #expect(!entitlement.hasAccess)
    #expect(entitlement.restoreOutcome == .noActiveEntitlement)
  }

  @Test
  func noSubscriptionStatusMapsToFree() {
    #expect(PremiumEntitlement.resolve(candidates: []) == .free)
  }

  @Test
  func expiredAndRevokedEntitlementsDoNotRestore() {
    let expirationDate = Date(timeIntervalSince1970: 1_700_000_000)

    let expired = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .expired,
          expirationDate: expirationDate,
          revocationDate: nil,
          isIntroductoryOffer: false
        )
      ]
    )
    let revoked = PremiumEntitlement.resolve(
      candidates: [
        EntitlementCandidate(
          productID: SnapDayPlusProduct.monthly.rawValue,
          state: .revoked,
          expirationDate: nil,
          revocationDate: expirationDate,
          isIntroductoryOffer: false
        )
      ]
    )

    #expect(expired == .expired(expirationDate: expirationDate))
    #expect(revoked == .revoked(revocationDate: expirationDate))
    #expect(expired.restoreOutcome == .noActiveEntitlement)
    #expect(revoked.restoreOutcome == .noActiveEntitlement)
  }

  @Test
  func activeEntitlementRestoresSuccessfully() {
    let entitlement = PremiumEntitlement.subscribed(expirationDate: nil)

    #expect(entitlement.restoreOutcome == .restored(entitlement))
  }

  @Test
  func transactionIsExpiredAtItsExpirationDate() {
    let expirationDate = Date(timeIntervalSince1970: 1_800_000_000)
    let transaction = StoreTransaction(
      productID: SnapDayPlusProduct.monthly.rawValue,
      expirationDate: expirationDate,
      revocationDate: nil,
      isIntroductoryOffer: false,
      finish: {}
    )

    #expect(
      transaction.entitlement(at: expirationDate)
        == .expired(expirationDate: expirationDate)
    )
  }
}
