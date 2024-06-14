import Foundation
import ComposableArchitecture
import Common

@Reducer
public struct CalendarPickerFeature {

  // MARK: - Dependecies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.calendar) private var calendar

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var type: CalendarPickerType
    var date: Date
    var dates = Set<DateComponents>()
    var objectIdentifier: String?
    var actionIdentifier: String?
    var buttonTitle: String? {
      switch type {
      case .singleSelection(let calendarPickerConfirm):
        switch calendarPickerConfirm {
        case .navigationButton(let title):
          return title
        case .noConfirmation:
          return nil
        }
      case .multiSelection(let title):
        return title
      }
    }

    public init(
      type: CalendarPickerType,
      date: Date,
      objectIdentifier: String? = nil,
      actionIdentifier: String? = nil
    ) {
      self.type = type
      self.date = date
      self.objectIdentifier = objectIdentifier
      self.actionIdentifier = actionIdentifier
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case trailingButtonTapped
      case cancelButtonTapped
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case datesSelected([Date], objectIdentifier: String?, actionIdentifier: String?)
    }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.trailingButtonTapped):
        let dates = prepareDates(state: state)
        return .run { [dates, objectIdentifier = state.objectIdentifier, actionIdentifier = state.actionIdentifier] send in
          await send(.delegate(.datesSelected(dates, objectIdentifier: objectIdentifier, actionIdentifier: actionIdentifier)))
          await dismiss()
        }
      case .view(.cancelButtonTapped):
        return .run { send in
          await dismiss()
        }
      case .delegate:
        return .none
      case .binding(\.date):
        guard state.buttonTitle == nil else { return .none }
        let dates = prepareDates(state: state)
        return .run { [dates, objectIdentifier = state.objectIdentifier, actionIdentifier = state.actionIdentifier] send in
          await send(.delegate(.datesSelected(dates, objectIdentifier: objectIdentifier, actionIdentifier: actionIdentifier)))
          await dismiss()
        }
      case .binding:
        return .none
      }
    }
  }

  private func prepareDates(state: State) -> [Date] {
    switch state.type {
    case .singleSelection:
      [state.date]
    case .multiSelection:
      state
        .dates
        .compactMap { dateComponent in
          calendar.date(from: dateComponent)
        }
    }
  }
}
