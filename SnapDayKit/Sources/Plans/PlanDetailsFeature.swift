import ComposableArchitecture
import Foundation
import Models
import Repositories
import Utilities

@Reducer
public struct PlanDetailsFeature {

  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.calendar) private var calendar
  @Dependency(\.date.now) private var now
  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.uuid) private var uuid

  @ObservableState
  public struct State: Equatable, Identifiable {
    var plan: Plan
    var allowsManagement: Bool
    var activities: [Activity]
    var occurrences: [PlanOccurrence]
    var dayActivities: [DayActivity]
    var referenceDate: Date?
    var isLoading = false
    var isArchiveConfirmationPresented = false
    var isRestoreUnavailableAlertPresented = false
    var isSaveErrorPresented = false
    @Presents var newPlan: NewPlanFeature.State?

    public var id: Plan.ID { plan.id }

    public init(
      plan: Plan,
      allowsManagement: Bool,
      activities: [Activity] = [],
      occurrences: [PlanOccurrence] = [],
      dayActivities: [DayActivity] = [],
      referenceDate: Date? = nil
    ) {
      self.plan = plan
      self.allowsManagement = allowsManagement
      self.activities = activities
      self.occurrences = occurrences
      self.dayActivities = dayActivities
      self.referenceDate = referenceDate
    }

    public func hasSamePlanContent(as plan: Plan) -> Bool {
      self.plan == plan
    }

    public mutating func updatePlan(_ plan: Plan) {
      self.plan = plan
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case task
      case editButtonTapped
      case archiveButtonTapped
      case archiveCancelled
      case archiveConfirmed
      case createSimilarButtonTapped
      case restoreButtonTapped
      case restoreUnavailableDismissed
      case saveErrorDismissed
    }

    public enum InternalAction: Equatable {
      case detailsLoaded([Activity], PlanProgressSnapshot)
      case editActivitiesLoaded([Activity])
      case lifecyclePlanSaved(Plan)
      case operationFailed
      case planSaveFailed
      case planSaved(Plan)
      case similarActivitiesLoaded([Activity])
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
      case .view(.task):
        state.isLoading = true
        state.referenceDate = now
        let plan = state.plan
        let knownActivities = state.activities
        let activityIDs = Set(plan.schedule.map(\.activityID))
        return .run { send in
          do {
            async let activitiesRequest = loadActivities()
            async let snapshots = PlanProgressProvider().snapshots(for: [plan])
            let loadedActivities = try await activitiesRequest
            guard let snapshot = try await snapshots.first else {
              await send(.internal(.operationFailed))
              return
            }
            let activities = PlanActivityResolver.orderedActivities(
              for: plan.schedule,
              merging: [
                knownActivities.filter { activityIDs.contains($0.id) },
                snapshot.dayActivities.compactMap(\.activity),
                loadedActivities.filter { activityIDs.contains($0.id) }
              ]
            )
            await send(.internal(.detailsLoaded(activities, snapshot)))
          } catch {
            await send(.internal(.operationFailed))
          }
        }
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
      case .view(.createSimilarButtonTapped):
        let activityIDs = Set(state.plan.schedule.map(\.activityID))
        let schedule = state.plan.schedule
        let availableActivities = state.activities.filter { activityIDs.contains($0.id) }
        if Set(availableActivities.map(\.id)) == activityIDs {
          return .send(.internal(.similarActivitiesLoaded(availableActivities)))
        }
        return .run { send in
          do {
            let loadedActivities = try await loadActivities()
            let activities = PlanActivityResolver.orderedActivities(
              for: schedule,
              merging: [availableActivities, loadedActivities]
            )
            await send(.internal(.similarActivitiesLoaded(activities)))
          } catch {
            await send(.internal(.operationFailed))
          }
        }
      case .view(.restoreButtonTapped):
        guard state.plan.isArchived else { return .none }
        let today = calendar.startOfDay(for: now)
        guard !state.plan.schedule.isEmpty,
              calendar.startOfDay(for: state.plan.endDate) >= today
        else {
          state.isRestoreUnavailableAlertPresented = true
          return .none
        }
        var restoredPlan = state.plan
        restoredPlan.isArchived = false
        return saveLifecyclePlan(restoredPlan, synchronizingFrom: today)
      case .view(.restoreUnavailableDismissed):
        state.isRestoreUnavailableAlertPresented = false
        return .none
      case .view(.saveErrorDismissed):
        state.isSaveErrorPresented = false
        return .none
      case .internal(.editActivitiesLoaded(let activities)):
        state.newPlan = NewPlanFeature.State(
          plan: state.plan,
          activities: activities,
          now: now,
          calendar: calendar
        )
        return .none
      case .internal(.detailsLoaded(let activities, let snapshot)):
        state.activities = activities
        state.occurrences = snapshot.occurrences
        state.dayActivities = snapshot.dayActivities
        state.isLoading = false
        return .none
      case .internal(.lifecyclePlanSaved(let plan)):
        state.plan = plan
        state.allowsManagement = true
        state.newPlan = nil
        state.isRestoreUnavailableAlertPresented = false
        return .merge(
          .send(.view(.task)),
          .send(.delegate(.planUpdated))
        )
      case .internal(.planSaved(let plan)):
        state.plan = plan
        state.newPlan = nil
        state.isSaveErrorPresented = false
        return .merge(
          .send(.view(.task)),
          .send(.delegate(.planUpdated))
        )
      case .internal(.similarActivitiesLoaded(let activities)):
        state.isRestoreUnavailableAlertPresented = false
        state.newPlan = NewPlanFeature.State(
          copying: state.plan,
          activities: activities,
          startDate: now,
          calendar: calendar
        )
        return .none
      case .internal(.operationFailed):
        state.isLoading = false
        return .none
      case .internal(.planSaveFailed):
        state.isSaveErrorPresented = true
        return .none
      case .newPlan(.presented(.delegate(.cancelTapped))):
        state.newPlan = nil
        return .none
      case .newPlan(.presented(.delegate(.planCreated(let draft)))):
        let plan = draft.plan(id: uuid(), scheduleEntryID: { uuid() })
        return saveLifecyclePlan(plan, synchronizingFrom: plan.startDate)
      case .newPlan(.presented(.delegate(.planUpdated(let plan)))):
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
            await send(.internal(.planSaveFailed))
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

  private func saveLifecyclePlan(
    _ plan: Plan,
    synchronizingFrom date: Date
  ) -> EffectOf<Self> {
    .run { send in
      do {
        try await planRepository.savePlan(plan)
        _ = try await planRepository.synchronizeOccurrences(plan, date)
        await send(.internal(.lifecyclePlanSaved(plan)))
      } catch {
        await send(.internal(.operationFailed))
      }
    }
  }
}
