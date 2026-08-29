import ComposableArchitecture
import Foundation
import Payment
import Plans
import Testing
import Utilities
@testable import Application
@testable import Dashboard
@testable import Reports

@MainActor
struct ApplicationPremiumTests {

  @Test
  func freeUserRequestPresentsContextualPaywall() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.premiumEntitlement = .free
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.requestPremiumAccess(.secondActivePlan)) {
      $0.pendingPremiumAction = .secondActivePlan
      $0.paywall = PaywallFeature.State(context: .secondActivePlan)
    }
  }

  @Test
  func entitledUserContinuesWithoutPaywall() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.premiumEntitlement = .subscribed(expirationDate: nil)
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.requestPremiumAccess(.extendedReports))
    await store.receive(.premiumAccessGranted(.extendedReports))
    await store.receive(.reports(.reports(.premiumAccessGranted))) {
      $0.reports.reports.hasPremiumAccess = true
    }
  }

  @Test
  func successfulPurchaseResumesPendingActionExactlyOnce() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.premiumEntitlement = .free
    state.pendingPremiumAction = .collaborationInvitation
    state.paywall = PaywallFeature.State(context: .collaborationInvitation)
    let store = makeStore(initialState: state, userDefaults: userDefaults)
    let entitlement = PremiumEntitlement.trial(expirationDate: nil)

    await store.send(
      .paywall(.presented(.delegate(.purchaseCompleted(entitlement))))
    ) {
      $0.premiumEntitlement = entitlement
      $0.pendingPremiumAction = nil
      $0.paywall = nil
    }
    await store.receive(.reports(.reports(.premiumEntitlementUpdated(true)))) {
      $0.reports.reports.hasPremiumAccess = true
    }
    await store.receive(.dashboard(.premiumEntitlementUpdated(true)))
    await store.receive(.premiumAccessGranted(.collaborationInvitation))
    await store.receive(.dashboard(.dashboard(.premiumEntitlementUpdated(true)))) {
      $0.dashboard.dashboard.hasPremiumAccess = true
    }
    await store.receive(.dashboard(.premiumAccessGranted(.collaborationInvitation)))
    await store.receive(.dashboard(.dashboard(.day(.premiumEntitlementUpdated(true))))) {
      $0.dashboard.dashboard.day.hasPremiumAccess = true
    }
    await store.receive(.dashboard(.dashboard(.premiumAccessGranted(.collaborationInvitation))))

    #expect(store.state.reports.reports.hasPremiumAccess)
    #expect(store.state.dashboard.dashboard.hasPremiumAccess)
    #expect(store.state.dashboard.dashboard.day.hasPremiumAccess)
  }

  @Test
  func planWidgetPurchaseContinuesToPlans() async throws {
    let userDefaults = try makeUserDefaults()
    let state = makeState(userDefaults: userDefaults)
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.premiumAccessGranted(.planProgressWidget))
    await store.receive(.openDashboardRoute(.plans))
    store.exhaustivity = .off(showSkippedAssertions: false)
    await store.receive(.dashboard(.externalRoute(.plans)))

    let pathID = try #require(store.state.dashboard.path.ids.last)
    #expect(store.state.dashboard.path[id: pathID, case: \.plans] != nil)
  }

  @Test
  func successfulPurchaseReloadsWidgets() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.premiumEntitlement = .free
    state.paywall = PaywallFeature.State(context: .settings)
    let reloadRecorder = ReloadRecorder()
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      widgetReloader: WidgetReloader {
        reloadRecorder.record()
      }
    )
    let entitlement = PremiumEntitlement.subscribed(expirationDate: nil)

    await store.send(
      .paywall(.presented(.delegate(.purchaseCompleted(entitlement))))
    ) {
      $0.premiumEntitlement = entitlement
      $0.paywall = nil
    }
    await store.receive(.reports(.reports(.premiumEntitlementUpdated(true)))) {
      $0.reports.reports.hasPremiumAccess = true
    }
    await store.receive(.dashboard(.premiumEntitlementUpdated(true)))
    await store.receive(.dashboard(.dashboard(.premiumEntitlementUpdated(true)))) {
      $0.dashboard.dashboard.hasPremiumAccess = true
    }
    await store.receive(.dashboard(.dashboard(.day(.premiumEntitlementUpdated(true))))) {
      $0.dashboard.dashboard.day.hasPremiumAccess = true
    }
    await store.finish()

    #expect(reloadRecorder.count == 1)
  }

  @Test
  func losingPremiumAccessUpdatesMountedFeaturesWithoutChangingNavigation() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.selectedTab = .reports
    state.premiumEntitlement = .subscribed(expirationDate: nil)
    state.reports.reports.hasPremiumAccess = true
    state.dashboard.dashboard.hasPremiumAccess = true
    state.dashboard.dashboard.day.hasPremiumAccess = true
    state.dashboard.path.append(.plans(PlansFeature.State()))
    let navigationPath = state.dashboard.path
    let reloadRecorder = ReloadRecorder()
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      widgetReloader: WidgetReloader {
        reloadRecorder.record()
      }
    )
    let entitlement = PremiumEntitlement.billingRetry(expirationDate: nil)

    await store.send(.premiumEntitlementUpdated(entitlement)) {
      $0.premiumEntitlement = entitlement
    }
    await store.receive(.reports(.reports(.premiumEntitlementUpdated(false)))) {
      $0.reports.reports.hasPremiumAccess = false
    }
    await store.receive(.dashboard(.premiumEntitlementUpdated(false)))
    await store.receive(.dashboard(.dashboard(.premiumEntitlementUpdated(false)))) {
      $0.dashboard.dashboard.hasPremiumAccess = false
    }
    await store.receive(.dashboard(.dashboard(.day(.premiumEntitlementUpdated(false))))) {
      $0.dashboard.dashboard.day.hasPremiumAccess = false
    }
    await store.finish()

    #expect(store.state.selectedTab == .reports)
    #expect(store.state.dashboard.path == navigationPath)
    #expect(reloadRecorder.count == 1)
  }

  @Test
  func closingPaywallPreservesApplicationNavigation() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.selectedTab = .reports
    state.pendingPremiumAction = .extendedReports
    state.paywall = PaywallFeature.State(context: .extendedReports)
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.paywall(.presented(.delegate(.closeRequested)))) {
      $0.pendingPremiumAction = nil
      $0.paywall = nil
    }

    #expect(store.state.selectedTab == .reports)
  }

  @Test
  func legalLinksOpenTheirConfiguredDestinations() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.paywall = PaywallFeature.State(context: .settings)
    let recorder = URLRecorder()
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      openURL: { url in
        await recorder.record(url)
        return true
      }
    )

    await store.send(.paywall(.presented(.delegate(.legalLinkRequested(.terms)))))
    await store.send(.paywall(.presented(.delegate(.legalLinkRequested(.privacy)))))
    await store.finish()

    #expect(
      await recorder.urls == [
        PaywallFeature.LegalLink.terms.url,
        PaywallFeature.LegalLink.privacy.url
      ]
    )
  }

  private func makeUserDefaults() throws -> UserDefaults {
    let suiteName = "ApplicationPremiumTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    userDefaults.set(true, forKey: "isOnboardingShown")
    return userDefaults
  }

  private func makeState(userDefaults: UserDefaults) -> ApplicationFeature.State {
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    return withDependencies {
      $0.utcCalendar = calendar
      $0.date.now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    } operation: {
      ApplicationFeature.State(userDefaults: userDefaults)
    }
  }

  private func makeStore(
    initialState: ApplicationFeature.State,
    userDefaults: UserDefaults,
    openURL: @escaping @Sendable (URL) async -> Bool = { _ in false },
    widgetReloader: WidgetReloader = WidgetReloader(reloadAction: { })
  ) -> TestStoreOf<ApplicationFeature> {
    withDependencies {
      $0.deeplinkService = DeeplinkService()
      $0.openURL = OpenURLEffect(handler: openURL)
      $0.widgetReloader = widgetReloader
    } operation: {
      TestStore(
        initialState: initialState,
        reducer: { ApplicationFeature(userDefaults: userDefaults) }
      )
    }
  }
}

private actor URLRecorder {
  private(set) var urls: [URL] = []

  func record(_ url: URL) {
    urls.append(url)
  }
}

private final class ReloadRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var value = 0

  var count: Int {
    lock.withLock { value }
  }

  func record() {
    lock.withLock { value += 1 }
  }
}
