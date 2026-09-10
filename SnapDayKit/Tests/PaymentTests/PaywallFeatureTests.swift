import ComposableArchitecture
import Foundation
@testable import Payment
import Testing

@MainActor
struct PaywallFeatureTests {
  @Test
  func loadingProductsSelectsAnnualByDefault() async {
    let products = SubscriptionProduct.paywallTestProducts
    let store = TestStore(
      initialState: PaywallFeature.State(context: .settings)
    ) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.products = { products }
    }

    await store.send(.view(.appeared)) {
      $0.loadState = .loading
    }
    await store.receive(.internal(.productsLoaded(products))) {
      $0.products = [products[1], products[0]]
      $0.selectedProductID = SnapDayPlusProduct.annual.rawValue
      $0.loadState = .loaded
    }
  }

  @Test
  func productLoadingFailureCanBeRetried() async {
    let attempts = AttemptCounter()
    let products = SubscriptionProduct.paywallTestProducts
    let store = TestStore(
      initialState: PaywallFeature.State(context: .extendedReports)
    ) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.products = {
        if await attempts.next() == 1 {
          throw TestError.unavailable
        }
        return products
      }
    }

    await store.send(.view(.appeared)) {
      $0.loadState = .loading
    }
    await store.receive(.internal(.productsFailed)) {
      $0.loadState = .failed
    }
    await store.send(.view(.retryButtonTapped)) {
      $0.loadState = .loading
    }
    await store.receive(.internal(.productsLoaded(products))) {
      $0.products = [products[1], products[0]]
      $0.selectedProductID = SnapDayPlusProduct.annual.rawValue
      $0.loadState = .loaded
    }
  }

  @Test
  func successfulPurchaseDelegatesExactlyOnce() async {
    let entitlement = PremiumEntitlement.subscribed(expirationDate: nil)
    let annual = SubscriptionProduct.paywallTestProducts[1]
    var state = PaywallFeature.State(context: .secondActivePlan)
    state.products = [annual]
    state.selectedProductID = annual.id
    state.loadState = .loaded
    let store = TestStore(initialState: state) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.purchase = { _ in .purchased(entitlement) }
    }

    await store.send(.view(.purchaseButtonTapped)) {
      $0.operation = .purchasing
    }
    await store.receive(.internal(.purchaseFinished(.purchased(entitlement)))) {
      $0.operation = .idle
      $0.didCompletePurchase = true
    }
    await store.receive(.delegate(.purchaseCompleted(entitlement)))

    await store.send(.internal(.purchaseFinished(.purchased(entitlement))))
  }

  @Test
  func pendingPurchaseRemainsVisibleAndCannotRestart() async {
    let annual = SubscriptionProduct.paywallTestProducts[1]
    var state = PaywallFeature.State(context: .planProgressWidget)
    state.products = [annual]
    state.selectedProductID = annual.id
    state.loadState = .loaded
    let store = TestStore(initialState: state) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.purchase = { _ in .pending }
    }

    await store.send(.view(.purchaseButtonTapped)) {
      $0.operation = .purchasing
    }
    await store.receive(.internal(.purchaseFinished(.pending))) {
      $0.operation = .pending
    }
    await store.send(.view(.purchaseButtonTapped))
  }

  @Test
  func pendingPurchaseCompletesWhenEntitlementBecomesActive() async {
    let entitlement = PremiumEntitlement.subscribed(expirationDate: nil)
    var state = PaywallFeature.State(context: .planProgressWidget)
    state.operation = .pending
    let store = TestStore(initialState: state) {
      PaywallFeature()
    }

    await store.send(.internal(.entitlementUpdated(entitlement))) {
      $0.operation = .idle
      $0.didCompletePurchase = true
    }
    await store.receive(.delegate(.purchaseCompleted(entitlement)))

    await store.send(.internal(.entitlementUpdated(entitlement)))
  }

  @Test
  func cancellationKeepsPaywallReadyForAnotherAttempt() async {
    let annual = SubscriptionProduct.paywallTestProducts[1]
    var state = PaywallFeature.State(context: .settings)
    state.products = [annual]
    state.selectedProductID = annual.id
    state.loadState = .loaded
    let store = TestStore(initialState: state) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.purchase = { _ in .cancelled }
    }

    await store.send(.view(.purchaseButtonTapped)) {
      $0.operation = .purchasing
    }
    await store.receive(.internal(.purchaseFinished(.cancelled))) {
      $0.operation = .idle
      $0.feedback = .purchaseCancelled
    }
  }

  @Test
  func purchaseFailureIsRecoverable() async {
    let annual = SubscriptionProduct.paywallTestProducts[1]
    var state = PaywallFeature.State(context: .settings)
    state.products = [annual]
    state.selectedProductID = annual.id
    state.loadState = .loaded
    let store = TestStore(initialState: state) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.purchase = { _ in throw TestError.unavailable }
    }

    await store.send(.view(.purchaseButtonTapped)) {
      $0.operation = .purchasing
    }
    await store.receive(.internal(.purchaseFailed)) {
      $0.operation = .idle
      $0.feedback = .purchaseFailed
    }
  }

  @Test
  func restoreWithAccessUsesPurchaseCompletionDelegate() async {
    let entitlement = PremiumEntitlement.trial(expirationDate: nil)
    let store = TestStore(
      initialState: PaywallFeature.State(context: .settings)
    ) {
      PaywallFeature()
    } withDependencies: {
      $0.paymentClient.restore = { .restored(entitlement) }
    }

    await store.send(.view(.restoreButtonTapped)) {
      $0.operation = .restoring
    }
    await store.receive(.internal(.restoreFinished(.restored(entitlement)))) {
      $0.operation = .idle
      $0.didCompletePurchase = true
    }
    await store.receive(.delegate(.purchaseCompleted(entitlement)))
  }

  @Test
  func closeAndLegalActionsAreDelegatedWithoutMutatingState() async {
    let store = TestStore(
      initialState: PaywallFeature.State(context: .settings)
    ) {
      PaywallFeature()
    }

    await store.send(.view(.termsButtonTapped))
    await store.receive(.delegate(.legalLinkRequested(.terms)))
    await store.send(.view(.privacyButtonTapped))
    await store.receive(.delegate(.legalLinkRequested(.privacy)))
    await store.send(.view(.closeButtonTapped))
    await store.receive(.delegate(.closeRequested))
  }
}

private enum TestError: Error {
  case unavailable
}

private actor AttemptCounter {
  private var count = 0

  func next() -> Int {
    count += 1
    return count
  }
}

private extension SubscriptionProduct {
  static var paywallTestProducts: [Self] {
    [
      SubscriptionProduct(
        id: SnapDayPlusProduct.monthly.rawValue,
        displayName: "Monthly",
        displayPrice: "$4.99",
        subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
        isEligibleForIntroductoryOffer: false
      ),
      SubscriptionProduct(
        id: SnapDayPlusProduct.annual.rawValue,
        displayName: "Annual",
        displayPrice: "$29.99",
        subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .year),
        isEligibleForIntroductoryOffer: true
      )
    ]
  }
}
