import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common

@Reducer
public struct OnboardingFeature {

  public enum Tab: String {
    case welcome
    case featureHighlight
    case icloud
    case notification
  }

  public enum VisibileHighlight: Int, CaseIterable, Identifiable {
    public var id: Int { rawValue }
    case habitTracking = 0
    case takeControl
    case achieveGoals
  }

  // MARK: - Dependencies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    // MARK: - Properties

    var selectedTab = Tab.welcome
    var visibileHighlight: [VisibileHighlight] = [.habitTracking]

    var isButtonVisible: Bool = true

    var buttonTitle: String {
      switch selectedTab {
      case .welcome:
        String(localized: "Get Started", bundle: .module)
      case .featureHighlight, .icloud:
        String(localized: "Continue", bundle: .module)
      case .notification:
        String(localized: "Turn on", bundle: .module)
      }
    }

    var isSkipButtonShown: Bool {
      guard case .notification = selectedTab else { return false }
      return true
    }

    public init() { }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case nextButtonPressed
      case skipButtonPressed
    }
    public enum InternalAction: Equatable { 
      case showNextHighlight(highlight: VisibileHighlight)
    }
    public enum DelegateAction: Equatable { 
      case finished
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .view(.nextButtonPressed):
        switch state.selectedTab {
        case .welcome:
          state.selectedTab = .featureHighlight
          return .run { send in
            for highlight in VisibileHighlight.allCases.dropFirst(1) {
              try await Task.sleep(for: .seconds(1.0))
              await send(.internal(.showNextHighlight(highlight: highlight)))
            }
          }
        case .featureHighlight:
          state.selectedTab = .icloud
          return .none
        case .icloud:
          state.selectedTab = .notification
          return .none
        case .notification:
          return .run { send in
            let result = try await userNotificationCenterProvider.requestAuthorization()
            print("RequestAuthorization - \(result ? "authorized" : "unauthorized")")
            await send(.delegate(.finished))
          }
        }
      case .view(.skipButtonPressed):
        return .send(.delegate(.finished))
      case .internal(.showNextHighlight(let highlight)):
        state.visibileHighlight.append(highlight)
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
