import ComposableArchitecture
import SwiftUI
import Dashboard
import Reports
import Resources
import DeveloperTools
import UIKit.UIDevice

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
      .foregroundColor: UIColor.standardText
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

          NavigationStack {
            ReportsView(
              store: store.scope(
                state: \.reports,
                action: \.reports
              )
            )
          }
          .tabItem {
            Text("Reports", bundle: .module)
            Image(systemName: "doc.text")
          }
          .tag(ApplicationFeature.Tab.reports)
        }
      )
      .onAppear {
        store.send(.appeared)
      }
      .sheet(item: $store.scope(state: \.developerTools, action: \.developerTools)) { store in
        NavigationStack {
          DeveloperToolsView(store: store)
        }
        .presentationDetents([.medium, .large])
      }
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
//        #if DEBUG
        store.send(.deviceShaked)
//        #endif
      }
    }
  }
}
