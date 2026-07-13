import ComposableArchitecture
import Foundation

@Reducer
public struct NewPlanFeature {

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var name: String
    var selectedDuration: PlanDuration
    var startDate: Date
    var endDate: Date

    var canContinue: Bool {
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
      name: String = "",
      selectedDuration: PlanDuration = .oneMonth,
      startDate: Date = .now,
      endDate: Date? = nil
    ) {
      self.name = name
      self.selectedDuration = selectedDuration
      self.startDate = startDate
      self.endDate = endDate ?? selectedDuration.endDate(from: startDate)
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case cancelButtonTapped
      case continueButtonTapped
      case durationTapped(PlanDuration)
    }

    public enum DelegateAction: Equatable {
      case cancelTapped
    }

    case binding(BindingAction<State>)
    case delegate(DelegateAction)
    case view(ViewAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.startDate):
        if state.selectedDuration == .custom {
          state.endDate = max(state.endDate, state.startDate)
        } else {
          state.endDate = state.selectedDuration.endDate(from: state.startDate)
        }
        return .none
      case .binding(\.endDate):
        state.endDate = max(state.endDate, state.startDate)
        return .none
      case .binding:
        return .none
      case .delegate:
        return .none
      case .view(.cancelButtonTapped):
        return .send(.delegate(.cancelTapped))
      case .view(.continueButtonTapped):
        return .none
      case .view(.durationTapped(let duration)):
        state.selectedDuration = duration
        if duration != .custom {
          state.endDate = duration.endDate(from: state.startDate)
        }
        return .none
      }
    }
  }
}

public enum PlanDuration: String, CaseIterable, Equatable, Identifiable {
  case sevenDays
  case twoWeeks
  case oneMonth
  case threeMonths
  case sixMonths
  case oneYear
  case custom

  public var id: Self {
    self
  }

  var title: String.LocalizationValue {
    switch self {
    case .sevenDays:
      "7 days"
    case .twoWeeks:
      "2 weeks"
    case .oneMonth:
      "1 month"
    case .threeMonths:
      "3 months"
    case .sixMonths:
      "6 months"
    case .oneYear:
      "1 year"
    case .custom:
      "Custom"
    }
  }

  fileprivate func endDate(from startDate: Date) -> Date {
    let calendar = Calendar.autoupdatingCurrent
    switch self {
    case .sevenDays:
      return calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
    case .twoWeeks:
      return calendar.date(byAdding: .day, value: 14, to: startDate) ?? startDate
    case .oneMonth:
      return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
    case .threeMonths:
      return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
    case .sixMonths:
      return calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
    case .oneYear:
      return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
    case .custom:
      return startDate
    }
  }
}
