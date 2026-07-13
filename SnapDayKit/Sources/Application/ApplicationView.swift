import ComposableArchitecture
import SwiftUI
import Dashboard
import Reports
import Plans
import Onboarding
import ActivityDetails
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
      .sheet(item: $store.scope(state: \.newPlan, action: \.newPlan)) { store in
        NavigationStack {
          NewPlanView(store: store)
        }
        .presentationDetents([.large])
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
        NavigationStack(path: $store.scope(state: \.dashboardPath, action: \.dashboardPath)) {
          DashboardView(
            store: store.scope(
              state: \.dashboard,
              action: \.dashboard
            )
          )
        } destination: { store in
          destinationView(store: store)
        }
        .tabItem {
          Text("Dashboard", bundle: .module)
          Image(systemName: "rectangle.grid.2x2")
        }
        .tag(ApplicationFeature.Tab.dashboard)
        .toolbarBackground(.visible, for: .tabBar)

        NavigationStack(path: $store.scope(state: \.reportsPath, action: \.reportsPath)) {
          ReportsView(
            store: store.scope(
              state: \.reports,
              action: \.reports
            )
          )
        } destination: { store in
          destinationView(store: store)
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

  @ViewBuilder
  private func destinationView(store: StoreOf<ApplicationFeature.Path>) -> some View {
    switch store.state {
    case .activityDetails:
      if let store = store.scope(state: \.activityDetails, action: \.activityDetails) {
        ActivityDetailsView(store: store)
      }
    case .plans:
      if let store = store.scope(state: \.plans, action: \.plans) {
        PlansView(store: store)
      }
    }
  }
}
