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
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        DashboardView(
          store: store.scope(
            state: \.dashboard,
            action: \.dashboard
          )
        )
        .onAppear {
          store.send(.appeared)
        }
      } destination: { store in
        switch store.state {
        case .reports:
          if let store = store.scope(state: \.reports, action: \.reports) {
            ReportsView(store: store)
          }
        }
      }
      .sheet(item: $store.scope(state: \.developerTools, action: \.developerTools)) { store in
        NavigationStack {
          DeveloperToolsView(store: store)
        }
        .presentationDetents([.medium, .large])
      }
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
        #if DEBUG
        store.send(.deviceShaked)
        #endif
      }
    }
  }
}
