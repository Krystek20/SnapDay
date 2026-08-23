import ComposableArchitecture
import Resources
import SwiftUI
import UiComponents

public struct PaywallView: View {
  private let store: StoreOf<PaywallFeature>

  public init(store: StoreOf<PaywallFeature>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 15.0) {
        header
        benefits
        products
          .padding(.top, 15.0)
        bottomAction
      }
      .padding(15.0)
    }
    .scrollIndicators(.hidden)
    .background(Color.background)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color.background, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "Cancel", bundle: .module)) {
          store.send(.view(.closeButtonTapped))
        }
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
      }
    }
    .onAppear {
      store.send(.view(.appeared))
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text(store.context.title)
        .font(.title.bold())
        .foregroundStyle(Color.primaryText)

      Text(store.context.message)
        .font(.subheadline)
        .foregroundStyle(Color.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var benefits: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      benefit(
        title: String(localized: "Run multiple Plans at the same time", bundle: .module)
      )
      benefit(
        title: String(localized: "Understand long-term progress patterns", bundle: .module)
      )
      benefit(
        title: String(localized: "Keep progress visible on your Home Screen", bundle: .module)
      )
    }
    .padding(.vertical, 5.0)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func benefit(title: String) -> some View {
    HStack(spacing: 10.0) {
      Image(systemName: "checkmark.circle.fill")
        .font(.callout.weight(.semibold))
        .foregroundStyle(Color.actionBlue)
        .frame(width: 20.0, height: 20.0)
        .accessibilityHidden(true)

      Text(title)
        .font(.callout.weight(.medium))
        .foregroundStyle(Color.primaryText)
    }
  }

  @ViewBuilder
  private var products: some View {
    switch store.loadState {
    case .idle, .loading:
      HStack {
        Spacer()
        ProgressView()
          .controlSize(.large)
          .accessibilityLabel(Text("Loading offers", bundle: .module))
        Spacer()
      }
      .frame(minHeight: 110.0)

    case .loaded:
      VStack(spacing: 10.0) {
        ForEach(store.products) { product in
          productButton(product)
        }
      }

    case .failed:
      HStack(spacing: 10.0) {
        Image(systemName: "arrow.clockwise")
          .font(.callout.weight(.semibold))
          .foregroundStyle(Color.secondaryText)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 2.0) {
          Text("Offers could not be loaded", bundle: .module)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.primaryText)
          Text("Check your connection and try again.", bundle: .module)
            .font(.caption)
            .foregroundStyle(Color.secondaryText)
        }

        Spacer(minLength: 5.0)

        Button(String(localized: "Retry", bundle: .module)) {
          store.send(.view(.retryButtonTapped))
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.actionBlue)
      }
      .padding(10.0)
      .frame(maxWidth: .infinity, minHeight: 60.0)
      .background(Color.formBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8.0))
    }
  }

  private func productButton(_ product: SubscriptionProduct) -> some View {
    let isSelected = store.selectedProductID == product.id

    return Button {
      store.send(.view(.productTapped(product.id)))
    } label: {
      HStack(spacing: 10.0) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(isSelected ? Color.actionBlue : Color.secondaryText)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 5.0) {
          HStack(spacing: 5.0) {
            Text(product.isAnnual ? "Annual" : "Monthly", bundle: .module)
              .font(.headline)
              .foregroundStyle(Color.primaryText)

            if product.isAnnual {
              Text("Best value", bundle: .module)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.actionBlue)
                .padding(.horizontal, 5.0)
                .padding(.vertical, 2.0)
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: 5.0))
            }
          }

          Text(product.offerDescription)
            .font(.footnote)
            .foregroundStyle(Color.secondaryText)
        }

        Spacer(minLength: 10.0)

        VStack(alignment: .trailing, spacing: 2.0) {
          Text(product.displayPrice)
            .font(.title3.bold())
            .foregroundStyle(Color.primaryText)
          Text(product.billingPeriodText)
            .font(.caption)
            .foregroundStyle(Color.secondaryText)
        }
      }
      .multilineTextAlignment(.leading)
      .padding(15.0)
      .frame(maxWidth: .infinity, minHeight: 75.0, alignment: .leading)
      .background(isSelected ? Color.actionBlue.opacity(0.18) : Color.formBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8.0))
      .overlay {
        RoundedRectangle(cornerRadius: 8.0)
          .stroke(isSelected ? Color.actionBlue : Color.border, lineWidth: isSelected ? 1.5 : 1.0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var legalActions: some View {
    HStack(spacing: 15.0) {
      Button(String(localized: "Restore Purchases", bundle: .module)) {
        store.send(.view(.restoreButtonTapped))
      }
      Button(String(localized: "Terms", bundle: .module)) {
        store.send(.view(.termsButtonTapped))
      }
      Button(String(localized: "Privacy", bundle: .module)) {
        store.send(.view(.privacyButtonTapped))
      }
    }
    .font(.caption)
    .foregroundStyle(Color.secondaryText)
    .frame(maxWidth: .infinity)
    .disabled(store.operation.isBusy)
  }

  @ViewBuilder
  private var bottomAction: some View {
    VStack(spacing: 10.0) {
      if store.loadState != .failed {
        if let feedbackText {
          Text(feedbackText)
            .font(.footnote)
            .foregroundStyle(feedbackColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }

        Button(actionTitle) {
          store.send(.view(.purchaseButtonTapped))
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.selectedProduct == nil || store.operation.isBusy)
        .overlay {
          if store.operation == .purchasing || store.operation == .restoring {
            ProgressView()
              .tint(Color.pureWhite)
          }
        }
        .accessibilityValue(store.operation.isBusy ? Text("In progress", bundle: .module) : Text(""))

        if let product = store.selectedProduct {
          Text(product.renewalDescription)
            .font(.caption)
            .foregroundStyle(Color.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      legalActions
    }
    .padding(.vertical, 10.0)
  }

  private var actionTitle: String {
    guard let product = store.selectedProduct else {
      return String(localized: "Loading offers…", bundle: .module)
    }
    if product.isAnnual && product.isEligibleForIntroductoryOffer {
      return String(localized: "Start 14-day free trial", bundle: .module)
    }
    return String(localized: "Continue for \(product.displayPrice)", bundle: .module)
  }

  private var feedbackText: String? {
    if store.operation == .pending {
      return String(localized: "Your purchase is pending approval. Plus will unlock automatically when it completes.", bundle: .module)
    }
    switch store.feedback {
    case .purchaseCancelled:
      return String(localized: "Purchase canceled. You can continue whenever you are ready.", bundle: .module)
    case .noPurchasesFound:
      return String(localized: "No active purchases were found for this Apple Account.", bundle: .module)
    case .purchaseFailed:
      return String(localized: "We could not complete your purchase. Please try again.", bundle: .module)
    case .restoreFailed:
      return String(localized: "We could not restore purchases. Please try again.", bundle: .module)
    case nil:
      return nil
    }
  }

  private var feedbackColor: Color {
    switch store.feedback {
    case .purchaseFailed, .restoreFailed:
      Color.alertText
    default:
      Color.secondaryText
    }
  }
}

private extension SubscriptionProduct {
  var offerDescription: String {
    if isAnnual && isEligibleForIntroductoryOffer {
      return String(localized: "14-day free trial", bundle: .module)
    }
    return subscriptionPeriod.displayText
  }

  var billingPeriodText: String {
    switch subscriptionPeriod.unit {
    case .day: String(localized: "per day", bundle: .module)
    case .week: String(localized: "per week", bundle: .module)
    case .month: String(localized: "per month", bundle: .module)
    case .year: String(localized: "per year", bundle: .module)
    }
  }

  var renewalDescription: String {
    if isAnnual && isEligibleForIntroductoryOffer {
      return String(
        localized: "No payment today. After 14 days, \(displayPrice) per year. Renews automatically until canceled.",
        bundle: .module
      )
    }
    return String(
      localized: "\(displayPrice) \(billingPeriodText). Renews automatically until canceled.",
      bundle: .module
    )
  }
}

private extension SubscriptionPeriod {
  var displayText: String {
    switch (value, unit) {
    case (1, .day): String(localized: "1 day", bundle: .module)
    case (1, .week): String(localized: "1 week", bundle: .module)
    case (1, .month): String(localized: "1 month", bundle: .module)
    case (1, .year): String(localized: "1 year", bundle: .module)
    case (_, .day): String(localized: "\(value) days", bundle: .module)
    case (_, .week): String(localized: "\(value) weeks", bundle: .module)
    case (_, .month): String(localized: "\(value) months", bundle: .module)
    case (_, .year): String(localized: "\(value) years", bundle: .module)
    }
  }
}
