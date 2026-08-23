import ComposableArchitecture
import Foundation
import Payment
import Testing
import Utilities
@testable import Application

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
    await store.receive(.dashboard(.premiumAccessGranted(.extendedReports)))
  }

  @Test
  func successfulPurchaseResumesPendingActionExactlyOnce() async throws {
    let userDefaults = try makeUserDefaults()
    var state = makeState(userDefaults: userDefaults)
    state.premiumEntitlement = .free
    state.pendingPremiumAction = .planProgressWidget
    state.paywall = PaywallFeature.State(context: .planProgressWidget)
    let store = makeStore(initialState: state, userDefaults: userDefaults)
    let entitlement = PremiumEntitlement.trial(expirationDate: nil)

    await store.send(
      .paywall(.presented(.delegate(.purchaseCompleted(entitlement))))
    ) {
      $0.premiumEntitlement = entitlement
      $0.pendingPremiumAction = nil
      $0.paywall = nil
    }
    await store.receive(.premiumAccessGranted(.planProgressWidget))
    await store.receive(.dashboard(.premiumAccessGranted(.planProgressWidget)))
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
    openURL: @escaping @Sendable (URL) async -> Bool = { _ in false }
  ) -> TestStoreOf<ApplicationFeature> {
    withDependencies {
      $0.deeplinkService = DeeplinkService()
      $0.openURL = OpenURLEffect(handler: openURL)
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
