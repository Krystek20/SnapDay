import Foundation
import ComposableArchitecture
import Common
import MarkerForm
import Models
import EmojiPicker
import Utilities
import ActivityTaskForm

public struct ActivityFormFeature: Reducer, TodayProvidable {

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
  @Dependency(\.tagRepository.deleteTag) var deleteTag
  @Dependency(\.activityRepository.saveActivity) var saveActivity
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.uuid) var uuid

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
    @PresentationState var markerForm: MarkerFormFeature.State?
    @PresentationState var emojiPicker: EmojiPickerFeature.State?
    @PresentationState var activityTaskForm: ActivityTaskFormFeature.State?
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

    var weekdays: [Weekday] {
      @Dependency(\.calendar) var calendar
      return WeekdaysProvider(calendar: calendar).weekdays
    }

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
      case addedTagTapped(Tag)
      case existingTagTapped(Tag)
      case removeTagTapped(Tag)
      case iconTapped
      case pickPhotoTapped
      case removeImageTapped
      case saveButtonTapped
      case imageSelected(PhotoItem)
      case addTaskButtonTapped
      case editButtonTapped(ActivityTask)
      case removeButtonTapped(ActivityTask)
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

    case markerForm(PresentationAction<MarkerFormFeature.Action>)
    case emojiPicker(PresentationAction<EmojiPickerFeature.Action>)
    case activityTaskForm(PresentationAction<ActivityTaskFormFeature.Action>)

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
      case .view(.addedTagTapped(let tag)):
        removeTag(tag, state: &state)
        return .send(.internal(.loadTags))
      case .view(.existingTagTapped(let tag)):
        appendTag(tag, state: &state)
        return .send(.internal(.loadTags))
      case .view(.removeTagTapped(let tag)):
        return .run { send in
          try await deleteTag(tag)
          await send(.internal(.loadTags))
        }
      case .view(.iconTapped):
        state.emojiPicker = EmojiPickerFeature.State()
        return .none
      case .view(.pickPhotoTapped):
        state.isPhotoPickerPresented = true
        return .none
      case .view(.removeImageTapped):
        state.activity.icon = nil
        return .none
      case .view(.saveButtonTapped):
        state.activity.startDate = today
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
      case .view(.addTaskButtonTapped):
        state.activityTaskForm = ActivityTaskFormFeature.State(
          activityTask: ActivityTask(
            id: uuid()
          )
        )
        return .none
      case .view(.editButtonTapped(let activityTask)):
        state.activityTaskForm = ActivityTaskFormFeature.State(
          activityTask: activityTask
        )
        return .none
      case .view(.removeButtonTapped(let activityTask)):
        state.activity.tasks.removeAll(where: { $0.id == activityTask.id })
        return .none
      case .internal(.setExistingTags(let tags)):
        state.existingTags = tags
        return .none
      case .internal(.loadTags):
        return .run { [enteredTags = state.activity.tags] send in
          let existingTags = try await loadTags(enteredTags)
          await send(.internal(.setExistingTags(existingTags)))
        }
      case .internal(.setImageDate(let imageData)):
        state.activity.icon = Icon(
          id: uuid(),
          data: imageData
        )
        return .none
      case .delegate:
        return .none
      case .markerForm(.presented(.delegate(.tagCreated(let tag)))):
        state.newTag = .empty
        state.focus = nil
        appendTag(tag, state: &state)
        return .none
      case .markerForm:
        return .none
      case .emojiPicker(.presented(.delegate(.dataSelected(let data)))):
        return .run { [data] send in
          await send(.internal(.setImageDate(data)))
        }
      case .emojiPicker:
        return .none
      case .activityTaskForm(.presented(.delegate(.activityTask(let activityTask)))):
        if let index = state.activity.tasks.firstIndex(where: { $0.id == activityTask.id }) {
          state.activity.tasks[index] = activityTask
        } else {
          state.activity.tasks.append(activityTask)
        }
        return .none
      case .activityTaskForm:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$markerForm, action: /Action.markerForm) {
      MarkerFormFeature()
    }
    .ifLet(\.$emojiPicker, action: /Action.emojiPicker) {
      EmojiPickerFeature()
    }
    .ifLet(\.$activityTaskForm, action: /Action.activityTaskForm) {
      ActivityTaskFormFeature()
    }
  }

  // MARK: - Private

  private func showNewTag(state: inout State) {
    guard !state.newTag.isEmpty else { return }
    state.markerForm = MarkerFormFeature.State(
      markerType: .tag,
      name: state.newTag
    )
  }

  private func appendTag(_ tag: Tag, state: inout State) {
    guard !state.activity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.activity.tags.append(tag)
  }

  private func removeTag(_ tag: Tag, state: inout State) {
    guard state.activity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.activity.tags.removeAll(where: { $0.name == tag.name })
  }
}
