import Foundation
import ComposableArchitecture
import Common
import Models
import EmojiPicker

@Reducer
public struct DayActivityTaskFormFeature {

  public enum DayActivityTaskFormType {
    case new
    case edit
  }

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.date) var date
  @Dependency(\.uuid) var uuid
  @Dependency(\.calendar) var calendar

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    
    var dayActivityTask: DayActivityTask
    var isPhotoPickerPresented: Bool = false
    @Presents var emojiPicker: EmojiPickerFeature.State?
    var type: DayActivityTaskFormType
    var photoItem: PhotoItem?
    let availableDateHours: ClosedRange<Date>

    public init(
      dayActivityTask: DayActivityTask,
      type: DayActivityTaskFormType,
      availableDateHours: ClosedRange<Date>
    ) {
      self.dayActivityTask = dayActivityTask
      self.type = type
      self.availableDateHours = availableDateHours
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case iconTapped
      case pickPhotoTapped
      case removeImageTapped
      case imageSelected(PhotoItem)
      case saveButtonTapped
      case deleteButtonTapped
      case isDoneToggleChanged(Bool)
      case remindToggeled(Bool)
    }
    public enum InternalAction: Equatable { 
      case setImageDate(_ date: Data?)
    }
    public enum DelegateAction: Equatable {
      case dayActivityTaskDeleted(DayActivityTask)
      case dayActivityTaskUpdated(DayActivityTask)
      case dayActivityTaskCreated(DayActivityTask)
    }

    case emojiPicker(PresentationAction<EmojiPickerFeature.Action>)

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
      case .view(let viewAction):
        handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        handleInternalAction(internalAction, state: &state)
      case .emojiPicker(let action):
        handleEmojiPickerAction(action, state: &state)
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
    .ifLet(\.$emojiPicker, action: \.emojiPicker) {
      EmojiPickerFeature()
    }
  }

  func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .saveButtonTapped:
      return .run { [dayActivityTask = state.dayActivityTask, type = state.type] send in
        switch type {
        case .new:
          await send(.delegate(.dayActivityTaskCreated(dayActivityTask)))
        case .edit:
          await send(.delegate(.dayActivityTaskUpdated(dayActivityTask)))
        }
        await dismiss()
      }
    case .deleteButtonTapped:
      return .run { [dayActivityTask = state.dayActivityTask] send in
        await send(.delegate(.dayActivityTaskDeleted(dayActivityTask)))
        await dismiss()
      }
    case .isDoneToggleChanged(let value):
      state.dayActivityTask.doneDate = value ? date() : nil
      return .none
    case .iconTapped:
      state.emojiPicker = EmojiPickerFeature.State()
      return .none
    case .pickPhotoTapped:
      state.isPhotoPickerPresented = true
      return .none
    case .removeImageTapped:
      state.dayActivityTask.overview = nil
      return .none
    case .imageSelected(let item):
      return .run { send in
        let data = try await item.loadImageData(size: 140.0)
        await send(.internal(.setImageDate(data)))
      }
    case .remindToggeled(let value):
      state.dayActivityTask.reminderDate = value
      ? calendar.setHourAndMinute(date.now, toDate: state.availableDateHours.lowerBound)
      : nil
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setImageDate(let imageData):
      state.dayActivityTask.icon = Icon(
        id: uuid(),
        data: imageData
      )
      return .none
    }
  }

  private func handleEmojiPickerAction(_ action: PresentationAction<EmojiPickerFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dataSelected(let data))):
      return .run { [data] send in
        await send(.internal(.setImageDate(data)))
      }
    case .presented, .dismiss:
      return .none
    }
  }
}
