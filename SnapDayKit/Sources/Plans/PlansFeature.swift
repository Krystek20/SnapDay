import ComposableArchitecture
import Foundation
import Models
import Repositories
import Utilities

@Reducer
public struct PlansFeature {

  @Dependency(\.date.now) private var now
  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar
  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.planRepository) private var planRepository

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var selectedSection: PlansSection = .active
    var loadState: PlansLoadState = .idle
    var activePlans: [PlanListItem] = []
    var finishedPlans: [PlanListItem] = []
    var archivedPlans: [PlanListItem] = []
    @Presents var newPlan: NewPlanFeature.State?

    public init() { }

    init(
      selectedSection: PlansSection,
      loadState: PlansLoadState = .loaded,
      activePlans: [PlanListItem] = [],
      finishedPlans: [PlanListItem] = [],
      archivedPlans: [PlanListItem] = [],
      newPlan: NewPlanFeature.State? = nil
    ) {
      self.selectedSection = selectedSection
      self.loadState = loadState
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
      case planTapped(Plan.ID)
      case retryButtonTapped
    }

    public enum InternalAction: Equatable {
      case loadPlans
      case plansLoaded(PlansSnapshot)
      case plansLoadFailed(String)
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
    case `internal`(InternalAction)
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
        guard state.loadState == .idle else { return .none }
        return .send(.internal(.loadPlans))
      case .view(.retryButtonTapped):
        return .send(.internal(.loadPlans))
      case .view(.createPlanButtonTapped):
        state.newPlan = NewPlanFeature.State(startDate: now)
        return .none
      case .view(.planTapped):
        return .none
      case .internal(.loadPlans):
        state.loadState = .loading
        return .run { [now] send in
          do {
            await send(.internal(.plansLoaded(try await loadSnapshot(on: now))))
          } catch {
            await send(.internal(.plansLoadFailed(error.localizedDescription)))
          }
        }
      case .internal(.plansLoaded(let snapshot)):
        state.activePlans = snapshot.activePlans
        state.finishedPlans = snapshot.finishedPlans
        state.archivedPlans = snapshot.archivedPlans
        state.loadState = .loaded
        return .none
      case .internal(.plansLoadFailed(let message)):
        state.loadState = .failed(message)
        return .none
      case .newPlan(.presented(.delegate(.cancelTapped))):
        state.newPlan = nil
        return .none
      case .newPlan(.presented(.delegate(.planCreated(let draft)))):
        let plan = draft.plan(id: uuid(), scheduleEntryID: { uuid() })
        state.newPlan = nil
        state.loadState = .loading
        return .run { send in
          do {
            try await planRepository.savePlan(plan)
            _ = try await planRepository.synchronizeOccurrences(plan, plan.startDate)
            await send(.internal(.loadPlans))
          } catch {
            await send(.internal(.plansLoadFailed(error.localizedDescription)))
          }
        }
      case .newPlan:
        return .none
      }
    }
    .ifLet(\.$newPlan, action: \.newPlan) {
      NewPlanFeature()
    }
  }

  private func loadSnapshot(on date: Date) async throws -> PlansSnapshot {
    let plans = try await planRepository.loadPlans()
    let activities = try await loadActivities()
    let activitiesByID = Dictionary(uniqueKeysWithValues: activities.map { ($0.id, $0) })
    let progressSnapshots = try await PlanProgressProvider().snapshots(for: plans)
    var activePlans: [PlanListItem] = []
    var finishedPlans: [PlanListItem] = []
    var archivedPlans: [PlanListItem] = []

    for snapshot in progressSnapshots {
      let plan = snapshot.plan
      let activityIDs = Set(plan.schedule.map(\.activityID))
      let item = PlanListItem(
        plan: plan,
        activities: activityIDs.compactMap { activitiesByID[$0] }.sorted { $0.name < $1.name },
        occurrences: snapshot.occurrences,
        dayActivities: snapshot.dayActivities
      )

      switch plan.status(on: date, calendar: calendar) {
      case .active:
        activePlans.append(item)
      case .finished:
        finishedPlans.append(item)
      case .archived:
        archivedPlans.append(item)
      }
    }

    return PlansSnapshot(
      activePlans: activePlans,
      finishedPlans: finishedPlans,
      archivedPlans: archivedPlans
    )
  }
}
