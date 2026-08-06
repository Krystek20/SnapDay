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
    var archiveConfirmationPlanID: Plan.ID?
    @Presents var planDetails: PlanDetailsFeature.State?
    @Presents var newPlan: NewPlanFeature.State?

    var isHistoryEmpty: Bool {
      finishedPlans.isEmpty && archivedPlans.isEmpty
    }

    public init() { }

    init(
      selectedSection: PlansSection,
      loadState: PlansLoadState = .loaded,
      activePlans: [PlanListItem] = [],
      finishedPlans: [PlanListItem] = [],
      archivedPlans: [PlanListItem] = [],
      archiveConfirmationPlanID: Plan.ID? = nil,
      planDetails: PlanDetailsFeature.State? = nil,
      newPlan: NewPlanFeature.State? = nil
    ) {
      self.selectedSection = selectedSection
      self.loadState = loadState
      self.activePlans = activePlans
      self.finishedPlans = finishedPlans
      self.archivedPlans = archivedPlans
      self.archiveConfirmationPlanID = archiveConfirmationPlanID
      self.planDetails = planDetails
      self.newPlan = newPlan
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case appeared
      case createPlanButtonTapped
      case planTapped(Plan.ID)
      case archivePlanTapped(Plan.ID)
      case archivePlanCancelled
      case archivePlanConfirmed
      case retryButtonTapped
    }

    public enum InternalAction: Equatable {
      case archivePlan(Plan.ID)
      case loadPlans
      case plansLoaded(PlansSnapshot)
      case plansLoadFailed(String)
    }

    public enum DelegateAction: Equatable {
      case plansChanged
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
    case planDetails(PresentationAction<PlanDetailsFeature.Action>)
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
      case .delegate:
        return .none
      case .view(.appeared):
        guard state.loadState == .idle else { return .none }
        return .send(.internal(.loadPlans))
      case .view(.retryButtonTapped):
        return .send(.internal(.loadPlans))
      case .view(.createPlanButtonTapped):
        state.newPlan = NewPlanFeature.State(startDate: now)
        return .none
      case .view(.planTapped(let id)):
        guard let item = state.planItem(id: id) else { return .none }
        state.planDetails = PlanDetailsFeature.State(
          plan: item.plan,
          allowsManagement: true,
          activities: item.activities,
          occurrences: item.occurrences,
          dayActivities: item.dayActivities
        )
        return .none
      case .view(.archivePlanTapped(let id)):
        guard state.activePlans.contains(where: { $0.id == id }) else { return .none }
        state.archiveConfirmationPlanID = id
        return .none
      case .view(.archivePlanCancelled):
        state.archiveConfirmationPlanID = nil
        return .none
      case .view(.archivePlanConfirmed):
        guard let id = state.archiveConfirmationPlanID else { return .none }
        state.archiveConfirmationPlanID = nil
        return .send(.internal(.archivePlan(id)))
      case .internal(.archivePlan(let id)):
        state.loadState = .loading
        return .run { send in
          do {
            try await planRepository.archivePlan(id)
            await send(.internal(.loadPlans))
            await send(.delegate(.plansChanged))
          } catch {
            await send(.internal(.plansLoadFailed(error.localizedDescription)))
          }
        }
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
        let selectedPlanID = state.planDetails?.id
        let selectedPlanActivities = state.planDetails?.activities ?? []
        state.activePlans = snapshot.activePlans
        state.finishedPlans = snapshot.finishedPlans
        state.archivedPlans = snapshot.archivedPlans
        if let selectedPlanID, let item = state.planItem(id: selectedPlanID) {
          var activitiesByID = Dictionary(
            selectedPlanActivities.map { ($0.id, $0) },
            uniquingKeysWith: { _, latest in latest }
          )
          for activity in item.activities {
            activitiesByID[activity.id] = activity
          }
          var includedActivityIDs = Set<Activity.ID>()
          let activities = item.plan.schedule.compactMap { entry -> Activity? in
            guard includedActivityIDs.insert(entry.activityID).inserted else { return nil }
            return activitiesByID[entry.activityID]
          }
          state.planDetails = PlanDetailsFeature.State(
            plan: item.plan,
            allowsManagement: true,
            activities: activities,
            occurrences: item.occurrences,
            dayActivities: item.dayActivities
          )
        }
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
            await send(.delegate(.plansChanged))
          } catch {
            await send(.internal(.plansLoadFailed(error.localizedDescription)))
          }
        }
      case .newPlan(.presented(.delegate(.planUpdated(let plan)))):
        state.newPlan = nil
        state.loadState = .loading
        let firstAffectedOccurrenceDate = calendar.date(
          byAdding: .day,
          value: 1,
          to: calendar.startOfDay(for: now)
        ) ?? now
        return .run { send in
          do {
            try await planRepository.savePlan(plan)
            _ = try await planRepository.synchronizeOccurrences(plan, firstAffectedOccurrenceDate)
            await send(.internal(.loadPlans))
            await send(.delegate(.plansChanged))
          } catch {
            await send(.internal(.plansLoadFailed(error.localizedDescription)))
          }
        }
      case .newPlan:
        return .none
      case .planDetails(.presented(.delegate(.archivePlanTapped(let id)))):
        state.planDetails = nil
        return .send(.internal(.archivePlan(id)))
      case .planDetails(.presented(.delegate(.planUpdated))):
        return .merge(
          .send(.internal(.loadPlans)),
          .send(.delegate(.plansChanged))
        )
      case .planDetails:
        return .none
      }
    }
    .ifLet(\.$planDetails, action: \.planDetails) {
      PlanDetailsFeature()
    }
    .ifLet(\.$newPlan, action: \.newPlan) {
      NewPlanFeature()
    }
  }

  private func loadSnapshot(on date: Date) async throws -> PlansSnapshot {
    let plans = try await planRepository.loadPlans()
    let activities = try await loadActivities()
    let progressSnapshots = try await PlanProgressProvider().snapshots(for: plans)
    var activePlans: [PlanListItem] = []
    var finishedPlans: [PlanListItem] = []
    var archivedPlans: [PlanListItem] = []

    for snapshot in progressSnapshots {
      let plan = snapshot.plan
      let activityIDs = Set(plan.schedule.map(\.activityID))
      var activitiesByID = Dictionary(
        snapshot.dayActivities.compactMap(\.activity).map { ($0.id, $0) },
        uniquingKeysWith: { _, latest in latest }
      )
      for activity in activities where activityIDs.contains(activity.id) {
        activitiesByID[activity.id] = activity
      }
      var includedActivityIDs = Set<Activity.ID>()
      let item = PlanListItem(
        plan: plan,
        activities: plan.schedule.compactMap { entry -> Activity? in
          guard includedActivityIDs.insert(entry.activityID).inserted else { return nil }
          return activitiesByID[entry.activityID]
        },
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

private extension PlansFeature.State {
  func planItem(id: Plan.ID) -> PlanListItem? {
    (activePlans + finishedPlans + archivedPlans).first(where: { $0.id == id })
  }
}
