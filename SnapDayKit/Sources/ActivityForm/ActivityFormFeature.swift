import Foundation
import ComposableArchitecture
import Common
import TagForm
import Models
import EmojiPicker

public struct ActivityFormFeature: Reducer {

  public enum ActivityFormType {
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

  @Dependency(\.tagRepository.loadTags) var loadTags
  @Dependency(\.activityRepository.saveActivity) var saveActivity
  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {

    public enum Field: Hashable {
      case name
      case tag
    }

    @BindingState var activity: Activity
    @BindingState var newTag = String.empty
    @BindingState var focus: Field?
    @BindingState var isPhotoPickerPresented: Bool = false
    @PresentationState var addTag: TagFormFeature.State?
    @PresentationState var showEmojiPicker: EmojiPickerFeature.State?
    var photoItem: PhotoItem?
    var existingTags = [Tag]()
    var showAddTagButton: Bool { !newTag.isEmpty }
    var options = ActivityFrequency.allCases

    var showFrequencyOptions: Bool { activity.isRepeatable }
    var showWeekdaysView: Bool { activity.areWeekdaysRequried }
    var showMonthlyView: Bool { activity.areMonthlyScheduleRequried }
    var showMonthDays: Bool { activity.areMonthDaysRequried }
    var showMonthWeekdays: Bool { activity.areMonthWeekdaysRequried }
    var isSaveButtonDisabled: Bool { !activity.isActivityReadyToSave }

    let type: ActivityFormType

    public init(activity: Activity, type: ActivityFormType = .new) {
      self.activity = activity
      self.type = type
      self.focus = type.focus
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case submitTagTapped
      case addTagButtonTapped
      case tagTapped(Tag)
      case iconTapped
      case pickPhotoTapped
      case removeImageTapped
      case saveButtonTapped
      case imageSelected(PhotoItem)
    }
    public enum InternalAction: Equatable {
      case setExistingTags([Tag])
      case loadTags
      case setImageDate(_ date: Data?)
    }
    public enum DelegateAction: Equatable {
      case activityCreated(Activity)
      case activityUpdated(Activity)
    }

    case addTag(PresentationAction<TagFormFeature.Action>)
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
      case .view(.appeared):
        return .send(.internal(.loadTags))
      case .view(.submitTagTapped):
        showNewTag(state: &state)
        return .none
      case .view(.addTagButtonTapped):
        showNewTag(state: &state)
        return .none
      case .view(.tagTapped(let tag)):
        appendTag(tag, state: &state)
        return .send(.internal(.loadTags))
      case .view(.iconTapped):
        state.showEmojiPicker = EmojiPickerFeature.State()
        return .none
      case .view(.pickPhotoTapped):
        state.isPhotoPickerPresented = true
        return .none
      case .view(.removeImageTapped):
        state.activity.image = nil
        return .none
      case .view(.saveButtonTapped):
        return .run { [activity = state.activity, type = state.type] send in
          try await saveActivity(activity)
          switch type {
          case .new:
            await send(.delegate(.activityCreated(activity)))
          case .edit:
            await send(.delegate(.activityUpdated(activity)))
          }
          await dismiss()
        }
      case .view(.imageSelected(let item)):
        return .run { send in
          let data = try await item.loadImageData(size: 140.0)
          await send(.internal(.setImageDate(data)))
        }
      case .internal(.setExistingTags(let tags)):
        state.existingTags = tags
        return .none
      case .internal(.loadTags):
        return .run { [enteredTags = state.activity.tags] send in
          let existingTags = try await loadTags(enteredTags)
          await send(.internal(.setExistingTags(existingTags)))
        }
      case .internal(.setImageDate(let imageData)):
        state.activity.image = imageData
        return .none
      case .delegate:
        return .none
      case .addTag(.presented(.delegate(.tagCreated(let tag)))):
        state.newTag = .empty
        state.focus = nil
        appendTag(tag, state: &state)
        return .none
      case .addTag:
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
    .ifLet(\.$addTag, action: /Action.addTag) {
      TagFormFeature()
    }
    .ifLet(\.$showEmojiPicker, action: /Action.showEmojiPicker) {
      EmojiPickerFeature()
    }
  }

  // MARK: - Private

  private func showNewTag(state: inout State) {
    guard !state.newTag.isEmpty else { return }
    state.addTag = TagFormFeature.State(
      tag: Tag(name: state.newTag)
    )
  }

  private func appendTag(_ tag: Tag, state: inout State) {
    guard !state.activity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.activity.tags.append(tag)
  }
}