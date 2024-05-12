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

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    
    var dayActivityTask: DayActivityTask
    var isPhotoPickerPresented: Bool = false
    @Presents var showEmojiPicker: EmojiPickerFeature.State?
    var type: DayActivityTaskFormType
    var photoItem: PhotoItem?

    public init(
      dayActivityTask: DayActivityTask,
      type: DayActivityTaskFormType
    ) {
      self.dayActivityTask = dayActivityTask
      self.type = type
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
    }
    public enum InternalAction: Equatable { 
      case setImageDate(_ date: Data?)
    }
    public enum DelegateAction: Equatable {
      case dayActivityTaskDeleted(DayActivityTask)
      case dayActivityTaskUpdated(DayActivityTask)
      case dayActivityTaskCreated(DayActivityTask)
    }

    case showEmojiPicker(PresentationAction<EmojiPickerFeature.Action>)

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
      case .view(.saveButtonTapped):
        return .run { [dayActivityTask = state.dayActivityTask, type = state.type] send in
          switch type {
          case .new:
            await send(.delegate(.dayActivityTaskCreated(dayActivityTask)))
          case .edit:
            await send(.delegate(.dayActivityTaskUpdated(dayActivityTask)))
          }
          await dismiss()
        }
      case .view(.deleteButtonTapped):
        return .run { [dayActivityTask = state.dayActivityTask] send in
          await send(.delegate(.dayActivityTaskDeleted(dayActivityTask)))
          await dismiss()
        }
      case .view(.isDoneToggleChanged(let value)):
        state.dayActivityTask.doneDate = value ? date() : nil
        return .none
      case .view(.iconTapped):
        state.showEmojiPicker = EmojiPickerFeature.State()
        return .none
      case .view(.pickPhotoTapped):
        state.isPhotoPickerPresented = true
        return .none
      case .view(.removeImageTapped):
        state.dayActivityTask.overview = nil
        return .none
      case .view(.imageSelected(let item)):
        return .run { send in
          let data = try await item.loadImageData(size: 140.0)
          await send(.internal(.setImageDate(data)))
        }
      case .internal(.setImageDate(let imageData)):
        state.dayActivityTask.icon = Icon(
          id: uuid(),
          data: imageData
        )
        return .none
      case .showEmojiPicker(.presented(.delegate(.dataSelected(let data)))):
        return .run { [data] send in
          await send(.internal(.setImageDate(data)))
        }
      case .showEmojiPicker:
        return .none
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$showEmojiPicker, action: \.showEmojiPicker) {
      EmojiPickerFeature()
    }
  }
}
