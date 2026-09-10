import Foundation
import ComposableArchitecture
import Models
import Repositories
import Utilities

@Reducer
public struct DashboardPlansFeature: TodayProvidable {
  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.utcCalendar) private var calendar

  private enum CancelID {
    case load
  }

  @ObservableState
  public struct State: Equatable {
    var summaries: [DashboardPlanSummary] = []

    public init() { }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case allPlansTapped
      case planTapped(Plan)
    }

    public enum DelegateAction: Equatable {
      case allPlansTapped
      case planTapped(Plan)
    }

    case load
    case loaded([DashboardPlanSummary])
    case view(ViewAction)
    case delegate(DelegateAction)
  }

  public init() { }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .load:
        return .run { [date = today] send in
          do {
            await send(.loaded(try await loadSummaries(on: date)))
          } catch {
            print("error: \(error)")
          }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
      case .loaded(let summaries):
        state.summaries = summaries
        return .none
      case .view(.allPlansTapped):
        return .send(.delegate(.allPlansTapped))
      case .view(.planTapped(let plan)):
        return .send(.delegate(.planTapped(plan)))
      case .delegate:
        return .none
      }
    }
  }

  private func loadSummaries(on date: Date) async throws -> [DashboardPlanSummary] {
    let plans = try await planRepository.loadActivePlans(date)
    return try await PlanProgressProvider().snapshots(for: plans).map { snapshot in
      DashboardPlanSummary(
        plan: snapshot.plan,
        occurrences: snapshot.occurrences,
        dayActivities: snapshot.dayActivities,
        date: date,
        calendar: calendar
      )
    }
  }
}
