import ComposableArchitecture

@Reducer
public struct OnboardingFeature {

  @ObservableState
  public struct State: Equatable {
    var selectedGoal: OnboardingGoal?

    public init(selectedGoal: OnboardingGoal? = nil) {
      self.selectedGoal = selectedGoal
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case continueButtonTapped
      case goalTapped(OnboardingGoal)
      case skipButtonTapped
    }

    public enum DelegateAction: Equatable {
      case goalSelected(OnboardingGoal)
      case skipped
    }

    case view(ViewAction)
    case delegate(DelegateAction)
  }

  public init() { }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.goalTapped(let goal)):
        state.selectedGoal = goal
        return .none
      case .view(.continueButtonTapped):
        guard let selectedGoal = state.selectedGoal else { return .none }
        return .send(.delegate(.goalSelected(selectedGoal)))
      case .view(.skipButtonTapped):
        return .send(.delegate(.skipped))
      case .delegate:
        return .none
      }
    }
  }
}
