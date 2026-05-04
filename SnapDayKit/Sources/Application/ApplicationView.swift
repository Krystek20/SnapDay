import ComposableArchitecture
import SwiftUI
import Dashboard
import Reports
import Onboarding
import ActivityDetails
import Resources
import UIKit.UIDevice
#if DEBUG || BETA
import DeveloperTools
#endif

@MainActor
public struct ApplicationView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ApplicationFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ApplicationFeature>) {
    self.store = store

#warning("Move it")
    let appearance = UINavigationBarAppearance()
    appearance.backgroundColor = UIColor.background
    appearance.shadowImage = nil
    appearance.shadowColor = nil

    appearance.titleTextAttributes = [
      .font: UIFont.systemFont(ofSize: 16.0, weight: .medium),
      .foregroundColor: UIColor.primaryText
    ]

    let scrollEdgeAppearance = appearance.copy()
    scrollEdgeAppearance.shadowImage = nil
    scrollEdgeAppearance.shadowColor = nil

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .onAppear {
          store.send(.appeared)
        }
        #if DEBUG || BETA
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
  }

  @ViewBuilder
  private var content: some View {
    WithPerceptionTracking {
      if store.showOnboarding {
        onboardingView
      } else {
        tabView
      }
    }
  }

  private var onboardingView: some View {
    WithPerceptionTracking {
      NavigationStack {
        OnboardingView(
          store: store.scope(
            state: \.onboarding,
            action: \.onboarding
          )
        )
      }
    }
  }

  private var tabView: some View {
    WithPerceptionTracking {
      TabView(
        selection: $store.selectedTab,
        content: {
          NavigationStack {
            DashboardView(
              store: store.scope(
                state: \.dashboard,
                action: \.dashboard
              )
            )
          }
          .tabItem {
            Text("Dashboard", bundle: .module)
            Image(systemName: "rectangle.grid.2x2")
          }
          .tag(ApplicationFeature.Tab.dashboard)
          .toolbarBackground(.visible, for: .tabBar)

          NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ReportsView(
              store: store.scope(
                state: \.reports,
                action: \.reports
              )
            )
          } destination: { store in
            switch store.state {
            case .activityDetails:
              if let store = store.scope(state: \.activityDetails, action: \.activityDetails) {
                ActivityDetailsView(store: store)
              }
            }
          }
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
}
