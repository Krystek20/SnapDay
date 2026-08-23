import ComposableArchitecture
import Dashboard
import Foundation
import Models
import Plans
import Repositories
import Utilities

@Reducer
public struct DashboardCoordinatorFeature {

  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.date.now) private var now

  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()
    var dashboard = DashboardFeature.State(date: Calendar.today)

    public init() { }
  }

  public enum Action: Equatable {
    case dashboard(DashboardFeature.Action)
    case externalRoute(ExternalRoute)
    case externalPlanLoaded(Plan?)
    case path(StackAction<Path.State, Path.Action>)
  }

  public enum ExternalRoute: Equatable {
    case plan(Plan.ID)
    case plans
  }

  @Reducer
  public struct Path {

    @ObservableState
    public enum State: Equatable {
      case planDetails(PlanDetailsFeature.State)
      case plans(PlansFeature.State)
    }

    public enum Action: Equatable {
      case planDetails(PlanDetailsFeature.Action)
      case plans(PlansFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      EmptyReducer<State, Action>()
        .ifCaseLet(\.planDetails, action: \.planDetails) {
          PlanDetailsFeature()
        }
        .ifCaseLet(\.plans, action: \.plans) {
          PlansFeature()
        }
    }
  }

  private enum CancelID {
    case externalPlan
  }

  public init() { }

  public var body: some ReducerOf<Self> {
    Scope(state: \.dashboard, action: \.dashboard) {
      DashboardFeature()
    }

    Reduce { state, action in
      switch action {
      case .dashboard(.delegate(.allPlansTapped)):
        state.path.append(.plans(PlansFeature.State()))
        return .none
      case .dashboard(.delegate(.planTapped(let plan))):
        state.path.append(
          .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
        )
        return .none
      case .dashboard:
        return .none
      case .externalRoute(.plans):
        state.path.removeAll()
        state.path.append(.plans(PlansFeature.State()))
        return .cancel(id: CancelID.externalPlan)
      case .externalRoute(.plan(let planID)):
        return .run { send in
          await send(.externalPlanLoaded(try? await planRepository.plan(planID)))
        }
        .cancellable(id: CancelID.externalPlan, cancelInFlight: true)
      case .externalPlanLoaded(let plan):
        if let plan {
          if let pathID = state.path.ids.last,
             var details = state.path[id: pathID, case: \.planDetails] {
            let isSamePlan = details.id == plan.id
            let shouldRefresh = !details.hasSamePlanContent(as: plan)
            if isSamePlan {
              details.updatePlan(plan)
            } else {
              details = PlanDetailsFeature.State(plan: plan, allowsManagement: true)
            }
            state.path[id: pathID, case: \.planDetails] = details
            return shouldRefresh && isSamePlan
              ? .send(.path(.element(id: pathID, action: .planDetails(.view(.task)))))
              : .none
          }

          state.path.removeAll()
          state.path.append(
            .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
          )
        } else {
          state.path.removeAll()
          state.path.append(.plans(PlansFeature.State()))
        }
        return .none
      case .path(.element(
        id: let pathID,
        action: .planDetails(.delegate(.archivePlanTapped(let planID)))
      )):
        return .run { send in
          do {
            try await planRepository.archivePlan(planID, now)
            await send(.path(.popFrom(id: pathID)))
            await send(.dashboard(.internal(.load)))
          } catch {
            return
          }
        }
      case .path(.element(
        id: let pathID,
        action: .planDetails(.delegate(.deletePlanTapped(let planID)))
      )):
        return .run { send in
          do {
            try await planRepository.deletePlan(planID, now)
            await send(.path(.popFrom(id: pathID)))
            await send(.dashboard(.internal(.load)))
          } catch {
            return
          }
        }
      case .path(.element(
        id: _,
        action: .planDetails(.delegate(.planUpdated))
      )):
        return .send(.dashboard(.internal(.load)))
      case .path(.element(
        id: _,
        action: .plans(.delegate(.plansChanged))
      )):
        return .send(.dashboard(.internal(.load)))
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
    }
  }
}
