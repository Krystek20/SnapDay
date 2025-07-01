import Foundation
import ComposableArchitecture
import Utilities
import Models
import Repositories
import struct UiComponents.ListItem

@Reducer
public struct DayActivityReminderFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.utcCalendar) private var calendar

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum DayActivityReminderType: Equatable {
      case activity(String)
      case activityTask(String)
    }

    let type: DayActivityReminderType
    var items: [ListItem] = []

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
          guard let dayActivity = try await dayUpdater.dayActivity(identifier: identifier) else { return }
          await send(.internal(.setActivity(dayActivity)))
        case .activityTask(let identifier):
          guard let dayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier),
                let dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) else { return }
          await send(.internal(.setActivityTask(dayActivity, dayActivityTask)))
        }
      }
    case .setActivity(let dayActivity):
      state.items = [
        dayActivity.listItem()
      ]
      return .none
    case .setActivityTask(let dayActivity, let dayActivityTask):
      state.items = [
        dayActivity.listItem(divider: .indented),
        dayActivityTask.listItem(parentId: dayActivity.id)
      ]
      return .none
    }
  }
}
