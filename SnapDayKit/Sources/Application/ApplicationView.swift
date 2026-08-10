import ComposableArchitecture
import SwiftUI
import Onboarding
import Resources
import UIKit.UIDevice
#if DEBUG
import DeveloperTools
#endif

@MainActor
public struct ApplicationView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<ApplicationFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ApplicationFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    content
      .onAppear {
        store.send(.appeared)
      }
      #if DEBUG
      .sheet(item: $store.scope(state: \.developerTools, action: \.developerTools)) { store in
        NavigationStack {
          DeveloperToolsView(store: store)
        }
        .presentationDetents([.medium, .large])
      }
      #endif
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
        store.send(.deviceShaked)
      }
  }

  @ViewBuilder
  private var content: some View {
    if store.showOnboarding {
      onboardingView
    } else {
      tabView
    }
  }

  private var onboardingView: some View {
    NavigationStack {
      OnboardingView(
        store: store.scope(
          state: \.onboarding,
          action: \.onboarding
        )
      )
    }
  }

  private var tabView: some View {
    TabView(
      selection: $store.selectedTab,
      content: {
        DashboardCoordinatorView(
          store: store.scope(state: \.dashboard, action: \.dashboard)
        )
        .tabItem {
          Text("Dashboard", bundle: .module)
          Image(systemName: "rectangle.grid.2x2")
        }
        .tag(ApplicationFeature.Tab.dashboard)
        .toolbarBackground(.visible, for: .tabBar)

        ReportsCoordinatorView(
          store: store.scope(state: \.reports, action: \.reports)
        )
        .tabItem {
          Text("Reports", bundle: .module)
          Image(systemName: "doc.text")
        }
        .tag(ApplicationFeature.Tab.reports)
        .toolbarBackground(.visible, for: .tabBar)
      }
    )
  }

}
