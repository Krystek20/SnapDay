import ComposableArchitecture
import SwiftUI

#Preview("Annual trial") {
  NavigationStack {
    PaywallView(
      store: Store(
        initialState: PaywallFeature.State(context: .secondActivePlan)
      ) {
        PaywallFeature()
      } withDependencies: {
        $0.paymentClient.products = { .paywallPreview }
      }
    )
  }
}

#Preview("Product loading failure") {
  NavigationStack {
    PaywallView(
      store: Store(
        initialState: PaywallFeature.State(context: .extendedReports)
      ) {
        PaywallFeature()
      } withDependencies: {
        $0.paymentClient.products = { throw PreviewError.unavailable }
      }
    )
  }
}

#Preview("Pending · dark · compact") {
  var state = PaywallFeature.State(context: .planProgressWidget)
  state.products = .paywallPreview
  state.selectedProductID = SnapDayPlusProduct.annual.rawValue
  state.loadState = .loaded
  state.operation = .pending

  return NavigationStack {
    PaywallView(
      store: Store(initialState: state) {
        PaywallFeature()
      }
    )
  }
  .preferredColorScheme(.dark)
}

#Preview("Accessibility text") {
  var state = PaywallFeature.State(context: .collaborationInvitation)
  state.products = .paywallPreview
  state.selectedProductID = SnapDayPlusProduct.annual.rawValue
  state.loadState = .loaded

  return NavigationStack {
    PaywallView(
      store: Store(initialState: state) {
        PaywallFeature()
      }
    )
  }
  .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

private enum PreviewError: Error {
  case unavailable
}

private extension Array where Element == SubscriptionProduct {
  static var paywallPreview: Self {
    [
      SubscriptionProduct(
        id: SnapDayPlusProduct.monthly.rawValue,
        displayName: "SnapDay Plus Monthly",
        displayPrice: "$4.99",
        subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
        isEligibleForIntroductoryOffer: false
      ),
      SubscriptionProduct(
        id: SnapDayPlusProduct.annual.rawValue,
        displayName: "SnapDay Plus Annual",
        displayPrice: "$29.99",
        subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .year),
        isEligibleForIntroductoryOffer: true
      )
    ]
  }
}
