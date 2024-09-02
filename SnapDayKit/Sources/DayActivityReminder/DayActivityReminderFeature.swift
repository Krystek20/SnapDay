import Foundation
import ComposableArchitecture
import Utilities
import Models
import Repositories

@Reducer
public struct DayActivityReminderFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum DayActivityReminderType: Equatable {
      case activity(String)
      case activityTask(String)
    }

    public enum DayActivityViewType: Equatable {
      case activity(DayActivity)
      case activityTask(DayActivity, DayActivityTask)
    }

    let type: DayActivityReminderType
    var viewType: DayActivityViewType?

    public init(type: DayActivityReminderType) {
      self.type = type
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
    }
    public enum InternalAction: Equatable {
      case load
      case setActivity(DayActivity)
      case setActivityTask(DayActivity, DayActivityTask)
    }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .binding:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .send(.internal(.load))
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .load:
      return .run { [type = state.type] send in
        switch type {
        case .activity(let identifier):
          guard let dayActivity = try await dayActivityRepository.activity(identifier) else { return }
          await send(.internal(.setActivity(dayActivity)))
        case .activityTask(let identifier):
          guard let dayActivityTask = try await dayActivityRepository.activityTask(identifier),
                let dayActivity = try await dayActivityRepository.activity(dayActivityTask.dayActivityId.uuidString) else { return }
          await send(.internal(.setActivityTask(dayActivity, dayActivityTask)))
        }
      }
    case .setActivity(let dayActivity):
      state.viewType = .activity(dayActivity)
      return .none
    case .setActivityTask(let dayActivity, let dayActivityTask):
      state.viewType = .activityTask(dayActivity, dayActivityTask)
      return .none
    }
  }
}
