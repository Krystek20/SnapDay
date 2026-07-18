import ComposableArchitecture
import Models
import Repositories

@Reducer
public struct PlanDetailsFeature {

  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.calendar) private var calendar
  @Dependency(\.date.now) private var now
  @Dependency(\.planRepository) private var planRepository

  @ObservableState
  public struct State: Equatable, Identifiable {
    var plan: Plan
    let allowsManagement: Bool
    var isArchiveConfirmationPresented = false
    @Presents var newPlan: NewPlanFeature.State?

    public var id: Plan.ID { plan.id }

    public init(plan: Plan, allowsManagement: Bool) {
      self.plan = plan
      self.allowsManagement = allowsManagement
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case editButtonTapped
      case archiveButtonTapped
      case archiveCancelled
      case archiveConfirmed
    }

    public enum InternalAction: Equatable {
      case editActivitiesLoaded([Activity])
      case operationFailed
      case planSaved(Plan)
    }

    public enum DelegateAction: Equatable {
      case archivePlanTapped(Plan.ID)
      case planUpdated
    }

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
    case newPlan(PresentationAction<NewPlanFeature.Action>)
  }

  public init() { }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.editButtonTapped):
        guard state.allowsManagement else { return .none }
        let activityIDs = Set(state.plan.schedule.map(\.activityID))
        return .run { send in
          do {
            let activities = try await loadActivities()
              .filter { activityIDs.contains($0.id) }
            await send(.internal(.editActivitiesLoaded(activities)))
          } catch {
            await send(.internal(.operationFailed))
          }
        }
      case .view(.archiveButtonTapped):
        guard state.allowsManagement else { return .none }
        state.isArchiveConfirmationPresented = true
        return .none
      case .view(.archiveCancelled):
        state.isArchiveConfirmationPresented = false
        return .none
      case .view(.archiveConfirmed):
        guard state.allowsManagement else { return .none }
        state.isArchiveConfirmationPresented = false
        return .send(.delegate(.archivePlanTapped(state.id)))
      case .internal(.editActivitiesLoaded(let activities)):
        state.newPlan = NewPlanFeature.State(
          plan: state.plan,
          activities: activities,
          now: now,
          calendar: calendar
        )
        return .none
      case .internal(.planSaved(let plan)):
        state.plan = plan
        return .send(.delegate(.planUpdated))
      case .internal(.operationFailed):
        return .none
      case .newPlan(.presented(.delegate(.cancelTapped))):
        state.newPlan = nil
        return .none
      case .newPlan(.presented(.delegate(.planUpdated(let plan)))):
        state.newPlan = nil
        let firstAffectedOccurrenceDate = calendar.date(
          byAdding: .day,
          value: 1,
          to: calendar.startOfDay(for: now)
        ) ?? now
        return .run { send in
          do {
            try await planRepository.savePlan(plan)
            _ = try await planRepository.synchronizeOccurrences(plan, firstAffectedOccurrenceDate)
            await send(.internal(.planSaved(plan)))
          } catch {
            await send(.internal(.operationFailed))
          }
        }
      case .newPlan:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$newPlan, action: \.newPlan) {
      NewPlanFeature()
    }
  }
}
