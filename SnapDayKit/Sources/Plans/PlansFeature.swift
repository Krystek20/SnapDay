import ComposableArchitecture
import Foundation

@Reducer
public struct PlansFeature {

  @Dependency(\.date.now) private var now
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var selectedSection: PlansSection = .active
    var activePlans: [Plan] = Plan.activeMocks
    var finishedPlans: [Plan] = Plan.finishedMocks
    var archivedPlans: [Plan] = Plan.archivedMocks
    @Presents var newPlan: NewPlanFeature.State?

    public init() { }

    init(
      selectedSection: PlansSection,
      activePlans: [Plan] = Plan.activeMocks,
      finishedPlans: [Plan] = Plan.finishedMocks,
      archivedPlans: [Plan] = Plan.archivedMocks,
      newPlan: NewPlanFeature.State? = nil
    ) {
      self.selectedSection = selectedSection
      self.activePlans = activePlans
      self.finishedPlans = finishedPlans
      self.archivedPlans = archivedPlans
      self.newPlan = newPlan
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case appeared
      case createPlanButtonTapped
      case planTapped(String)
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
    case newPlan(PresentationAction<NewPlanFeature.Action>)
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
      case .view(.appeared):
        return .none
      case .view(.createPlanButtonTapped):
        state.newPlan = NewPlanFeature.State(startDate: now)
        return .none
      case .view(.planTapped):
        return .none
      case .newPlan(.presented(.delegate(.cancelTapped))):
        state.newPlan = nil
        return .none
      case .newPlan(.presented(.delegate(.planCreated(let draft)))):
        let total = draft.plannedActivityCount()
        state.activePlans.insert(
          Plan(
            id: uuid().uuidString,
            title: draft.name,
            summary: "0 of \(total) planned activities complete",
            activities: draft.uniqueActivities.map(\.name),
            progress: 0.0,
            progressTitle: "0%"
          ),
          at: 0
        )
        state.selectedSection = .active
        state.newPlan = nil
        return .none
      case .newPlan:
        return .none
      }
    }
    .ifLet(\.$newPlan, action: \.newPlan) {
      NewPlanFeature()
    }
  }
}
