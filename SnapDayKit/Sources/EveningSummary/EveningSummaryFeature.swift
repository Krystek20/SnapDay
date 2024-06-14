import Foundation
import ComposableArchitecture
import Utilities
import Models

struct EveningTagSummary: Identifiable, Equatable {
  var id: String { tag.id }
  let tag: Tag
  let dayActivities: [DayActivity]

  var totalDuration: Int {
    dayActivities.reduce(into: Int.zero, { result, dayActivity in
      result += dayActivity.totalDuration
    })
  }
}

@Reducer
public struct EveningSummaryFeature: TodayProvidable {

  // MARK: - Properties

  private var dayProvider = DayProvider()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var day: Day?

    var eveningTagSummaries: [EveningTagSummary] = []
    var completedActivities: CompletedActivities {
      day?.completedActivities ?? CompletedActivities(doneCount: .zero, totalCount: .zero, percent: .zero)
    }
    var showDoneView: Bool {
      day?.activities.filter { !$0.isDone }.isEmpty == true
    }
    var doneActivitiesCount: Int {
      day?.activities.filter(\.isDone).count ?? .zero
    }
    var doneActivitiesDuration: Int {
      day?.activities.filter(\.isDone).reduce(into: Int.zero, { result, dayActivity in
        result += dayActivity.totalDuration
      }) ?? .zero
    }

    let date: Date

    public init(date: Date) { 
      self.date = date
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
    }
    public enum InternalAction: Equatable {
      case loadDay
      case setDay(Day?)
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
      return .send(.internal(.loadDay))
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .loadDay:
      return .run { [date = state.date] send in
        let day = try await dayProvider.day(for: date)
        await send(.internal(.setDay(day)))
      }
    case .setDay(let day):
      guard let day else { return .none }
      let allTags = day.activities.reduce(into: [Tag](), { result, dayActivity in
        result += dayActivity.tags
      })
      let doneActivities = day.activities.filter(\.isDone)
      var eveningTagSummaries = Array(Set(allTags)).map { tag in
        EveningTagSummary(
          tag: tag,
          dayActivities: doneActivities.filter { $0.tags.contains(tag) }
        )
      }
      eveningTagSummaries.append(
        EveningTagSummary(
          tag: Tag(
            name: String(localized: "Others", bundle: .module),
            color: RGBColor(
              red: .zero,
              green: .zero,
              blue: .zero,
              alpha: 1.0
            )
          ),
          dayActivities: doneActivities.filter { $0.tags.isEmpty }
        )
      )
      state.eveningTagSummaries = eveningTagSummaries
        .filter { !$0.dayActivities.isEmpty }
        .sorted(by: { $0.tag.name < $1.tag.name })
      state.day = day
      return .none
    }
  }
}
