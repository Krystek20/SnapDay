import ComposableArchitecture
import Plans

@Reducer
public struct OnboardingFeature {

  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()
    var newPlan: NewPlanFeature.State?
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
      case completed
      case createPlanRequested(OnboardingPlanRequest)
      case planCreationCancelled
      case planCreated(NewPlanDraft)
      case skipped
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case newPlan(NewPlanFeature.Action)
    case path(StackAction<Path.State, Path.Action>)
    case presentPlan(NewPlanFeature.State)
  }

  @Reducer
  public struct Path {
    @ObservableState
    public enum State: Equatable {
      case newPlanStep(NewPlanStep)
      case templateSelection(OnboardingTemplateSelectionFeature.State)
    }

    public enum Action: Equatable {
      case newPlanStep
      case templateSelection(OnboardingTemplateSelectionFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      EmptyReducer<State, Action>()
        .ifCaseLet(\.templateSelection, action: \.templateSelection) {
          OnboardingTemplateSelectionFeature()
        }
    }
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
        switch selectedGoal {
        case .readMore:
          state.path.append(.templateSelection(.init(category: .reading)))
          return .none
        case .moveMore:
          state.path.append(.templateSelection(.init(category: .movement)))
          return .none
        case .healthyHabit:
          state.path.append(.templateSelection(.init(category: .healthyHabit)))
          return .none
        case .learnSomething:
          state.path.append(.templateSelection(.init(category: .learning)))
          return .none
        case .organizeMyDay:
          return .send(.delegate(.completed))
        case .createMyOwn:
          return .send(.delegate(.createPlanRequested(.empty)))
        }
      case .view(.skipButtonTapped):
        return .send(.delegate(.skipped))
      case .presentPlan(let planState):
        state.newPlan = planState
        state.path.append(.newPlanStep(.details))
        return .none
      case .path(.element(
        id: _,
        action: .templateSelection(.delegate(.createPlanRequested(let request)))
      )):
        return .send(.delegate(.createPlanRequested(request)))
      case .newPlan(.delegate(.cancelTapped)):
        guard let id = state.path.ids.last else { return .none }
        return .send(.path(.popFrom(id: id)))
      case .newPlan(.delegate(.planCreated(let draft))):
        return .send(.delegate(.planCreated(draft)))
      case .newPlan(.delegate(.stepChanged(let step))):
        guard state.path.last != .newPlanStep(step) else { return .none }
        state.path.append(.newPlanStep(step))
        return .none
      case .newPlan:
        return .none
      case .path(.popFrom(let id)):
        guard case .newPlanStep(let removedStep)? = state.path[id: id] else {
          return .none
        }
        switch removedStep {
        case .details:
          state.newPlan = nil
          return .send(.delegate(.planCreationCancelled))
        case .weeklySchedule:
          return .send(.newPlan(.view(.navigationPathChanged([]))))
        case .review:
          return .send(
            .newPlan(.view(.navigationPathChanged([.weeklySchedule])))
          )
        }
      case .path:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.newPlan, action: \.newPlan) {
      NewPlanFeature()
    }
    .forEach(\.path, action: \.path) {
      Path()
    }
  }
}
