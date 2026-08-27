import ComposableArchitecture
import Foundation
import OSLog

@Reducer
public struct PaywallFeature {
  @ObservableState
  public struct State: Equatable {
    public let context: PaywallEntryContext
    var products: [SubscriptionProduct] = []
    var selectedProductID: SubscriptionProduct.ID?
    var loadState = LoadState.idle
    var operation = Operation.idle
    var feedback: Feedback?
    var didCompletePurchase = false

    public init(context: PaywallEntryContext) {
      self.context = context
    }

    public var isOperationInProgress: Bool {
      operation.isBusy
    }

    var selectedProduct: SubscriptionProduct? {
      products.first { $0.id == selectedProductID }
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case closeButtonTapped
      case productTapped(SubscriptionProduct.ID)
      case purchaseButtonTapped
      case retryButtonTapped
      case restoreButtonTapped
      case termsButtonTapped
      case privacyButtonTapped
    }

    public enum InternalAction: Equatable {
      case productsLoaded([SubscriptionProduct])
      case productsFailed
      case purchaseFinished(PurchaseOutcome)
      case purchaseFailed
      case restoreFinished(RestoreOutcome)
      case restoreFailed
      case entitlementUpdated(PremiumEntitlement)
    }

    public enum DelegateAction: Equatable {
      case closeRequested
      case purchaseCompleted(PremiumEntitlement)
      case legalLinkRequested(LegalLink)
    }

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  public enum LegalLink: Equatable {
    case terms
    case privacy

    public var url: URL {
      let value = switch self {
      case .terms:
        "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
      case .privacy:
        "https://snapday-24dd5e.gitlab.io/privacy-policy-en.pdf"
      }
      guard let url = URL(string: value) else {
        preconditionFailure("Invalid paywall legal URL: \(value)")
      }
      return url
    }
  }

  enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
  }

  enum Operation: Equatable {
    case idle
    case purchasing
    case restoring
    case pending

    var isBusy: Bool {
      self != .idle
    }
  }

  enum Feedback: Equatable {
    case purchaseCancelled
    case noPurchasesFound
    case purchaseFailed
    case restoreFailed
  }

  @Dependency(\.paymentClient) private var paymentClient

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.appeared):
        guard state.loadState == .idle else { return .none }
        return loadProducts(state: &state)

      case .view(.closeButtonTapped):
        return .send(.delegate(.closeRequested))

      case .view(.productTapped(let productID)):
        guard state.products.contains(where: { $0.id == productID }) else { return .none }
        state.selectedProductID = productID
        state.feedback = nil
        return .none

      case .view(.purchaseButtonTapped):
        guard
          state.operation == .idle,
          let productID = state.selectedProductID
        else { return .none }

        state.operation = .purchasing
        state.feedback = nil
        return .run { send in
          do {
            let outcome = try await paymentClient.purchase(productID)
            await send(.internal(.purchaseFinished(outcome)))
          } catch {
            await send(.internal(.purchaseFailed))
          }
        }

      case .view(.retryButtonTapped):
        guard state.loadState == .failed else { return .none }
        return loadProducts(state: &state)

      case .view(.restoreButtonTapped):
        guard state.operation == .idle else { return .none }
        state.operation = .restoring
        state.feedback = nil
        return .run { send in
          do {
            let outcome = try await paymentClient.restore()
            await send(.internal(.restoreFinished(outcome)))
          } catch {
            await send(.internal(.restoreFailed))
          }
        }

      case .view(.termsButtonTapped):
        return .send(.delegate(.legalLinkRequested(.terms)))

      case .view(.privacyButtonTapped):
        return .send(.delegate(.legalLinkRequested(.privacy)))

      case .internal(.productsLoaded(let products)):
        guard !products.isEmpty else {
          Logger.payment.error("StoreKit returned no SnapDay Plus subscription products")
          state.loadState = .failed
          return .none
        }
        state.products = products.sorted(by: SubscriptionProduct.paywallOrder)
        state.selectedProductID = state.products.first(where: \.isAnnual)?.id
          ?? state.products.first?.id
        state.loadState = .loaded
        return .none

      case .internal(.productsFailed):
        state.loadState = .failed
        return .none

      case .internal(.purchaseFinished(.purchased(let entitlement))):
        guard !state.didCompletePurchase else { return .none }
        state.didCompletePurchase = true
        state.operation = .idle
        return .send(.delegate(.purchaseCompleted(entitlement)))

      case .internal(.purchaseFinished(.pending)):
        state.operation = .pending
        return .none

      case .internal(.purchaseFinished(.cancelled)):
        state.operation = .idle
        state.feedback = .purchaseCancelled
        return .none

      case .internal(.purchaseFailed):
        state.operation = .idle
        state.feedback = .purchaseFailed
        return .none

      case .internal(.restoreFinished(.restored(let entitlement))):
        guard !state.didCompletePurchase else { return .none }
        state.didCompletePurchase = true
        state.operation = .idle
        return .send(.delegate(.purchaseCompleted(entitlement)))

      case .internal(.restoreFinished(.noActiveEntitlement)):
        state.operation = .idle
        state.feedback = .noPurchasesFound
        return .none

      case .internal(.restoreFailed):
        state.operation = .idle
        state.feedback = .restoreFailed
        return .none

      case .internal(.entitlementUpdated(let entitlement)):
        guard
          state.operation == .pending,
          entitlement.hasAccess,
          !state.didCompletePurchase
        else { return .none }
        state.didCompletePurchase = true
        state.operation = .idle
        return .send(.delegate(.purchaseCompleted(entitlement)))

      case .delegate:
        return .none
      }
    }
  }

  private func loadProducts(state: inout State) -> Effect<Action> {
    state.loadState = .loading
    state.feedback = nil
    return .run { send in
      do {
        await send(.internal(.productsLoaded(try await paymentClient.products())))
      } catch {
        Logger.payment.error(
          "Unable to load subscription products: \(error.localizedDescription, privacy: .public)"
        )
        await send(.internal(.productsFailed))
      }
    }
  }
}

private extension Logger {
  static let payment = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.mobilove.snapday",
    category: "Payment"
  )
}

extension SubscriptionProduct {
  var isAnnual: Bool {
    id == SnapDayPlusProduct.annual.rawValue || subscriptionPeriod.unit == .year
  }

  fileprivate static func paywallOrder(lhs: Self, rhs: Self) -> Bool {
    if lhs.isAnnual != rhs.isAnnual {
      return lhs.isAnnual
    }
    return lhs.id < rhs.id
  }
}
