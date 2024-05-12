import Foundation
import ComposableArchitecture
import Common
import Models
import EmojiPicker
import Utilities

@Reducer
public struct ActivityTaskFormFeature: TodayProvidable {

  public enum ActivityTaskFormType {
    case new
    case edit

    fileprivate var focus: State.Field? {
      switch self {
      case .new: .name
      case .edit: nil
      }
    }
  }

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.uuid) var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum Field: Hashable {
      case name
      case tag
    }

    var activityTask: ActivityTask
    var focus: Field?
    var isPhotoPickerPresented: Bool = false
    @Presents var showEmojiPicker: EmojiPickerFeature.State?
    var photoItem: PhotoItem?
    var isSaveButtonDisabled: Bool { activityTask.name.isEmpty }

    let type: ActivityTaskFormType

    public init(activityTask: ActivityTask, type: ActivityTaskFormType) {
      self.activityTask = activityTask
      self.type = type
      self.focus = type.focus
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case iconTapped
      case pickPhotoTapped
      case removeImageTapped
      case saveButtonTapped
      case imageSelected(PhotoItem)
    }
    public enum InternalAction: Equatable {
      case setImageDate(_ date: Data?)
    }
    public enum DelegateAction: Equatable {
      case activityTask(ActivityTask)
      case activityTaskRemoved(ActivityTask)
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
      case .view(.iconTapped):
        state.showEmojiPicker = EmojiPickerFeature.State()
        return .none
      case .view(.pickPhotoTapped):
        state.isPhotoPickerPresented = true
        return .none
      case .view(.removeImageTapped):
        state.activityTask.icon = nil
        return .none
      case .view(.saveButtonTapped):
        return .run { [activityTask = state.activityTask] send in
          await send(.delegate(.activityTask(activityTask)))
          await dismiss()
        }
      case .view(.imageSelected(let item)):
        return .run { send in
          let data = try await item.loadImageData(size: 140.0)
          await send(.internal(.setImageDate(data)))
        }
      case .internal(.setImageDate(let imageData)):
        state.activityTask.icon = Icon(
          id: uuid(),
          data: imageData
        )
        return .none
      case .delegate:
        return .none
      case .showEmojiPicker(.presented(.delegate(.dataSelected(let data)))):
        return .run { [data] send in
          await send(.internal(.setImageDate(data)))
        }
      case .showEmojiPicker:
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
