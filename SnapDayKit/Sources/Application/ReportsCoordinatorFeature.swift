import ActivityDetails
import ComposableArchitecture
import Reports

@Reducer
public struct ReportsCoordinatorFeature {

  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()
    var reports = ReportsFeature.State()

    public init() { }
  }

  public enum Action: Equatable {
    case path(StackAction<Path.State, Path.Action>)
    case reports(ReportsFeature.Action)
  }

  @Reducer
  public struct Path {

    @ObservableState
    public enum State: Equatable {
      case activityDetails(ActivityDetailsFeature.State)
    }

    public enum Action: Equatable {
      case activityDetails(ActivityDetailsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      EmptyReducer<State, Action>()
        .ifCaseLet(\.activityDetails, action: \.activityDetails) {
          ActivityDetailsFeature()
        }
    }
  }

  public init() { }

  public var body: some ReducerOf<Self> {
    Scope(state: \.reports, action: \.reports) {
      ReportsFeature()
    }

    Reduce { state, action in
      switch action {
      case .reports(.delegate(.activityTapped(let activity, let activities, let period))):
        state.path.append(
          .activityDetails(
            ActivityDetailsFeature.State(
              reportType: .activity(activity, activities, nil),
              period: period
            )
          )
        )
        return .none
      case .reports(.delegate(.tagTapped(let tag, let tags, let period))):
        state.path.append(
          .activityDetails(
            ActivityDetailsFeature.State(
              reportType: .tag(tag, tags, nil),
              period: period
            )
          )
        )
        return .none
      case .reports, .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
    }
  }
}
