import Foundation
import ComposableArchitecture
import Common
import MarkerForm
import Models
import EmojiPicker
import Utilities
import ActivityTaskForm

@Reducer
public struct ActivityFormFeature: TodayProvidable {

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
  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.uuid) var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum Field: Hashable {
      case name
      case tag
    }

    var activity: Activity
    var newTag = String.empty
    var focus: Field?
    var isPhotoPickerPresented: Bool = false
    @Presents var markerForm: MarkerFormFeature.State?
    @Presents var emojiPicker: EmojiPickerFeature.State?
    @Presents var activityTaskForm: ActivityTaskFormFeature.State?
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
    var tasksToRemove: [ActivityTask] = []

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
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .markerForm(let action):
        return handleMarkerFormAction(action, state: &state)
      case .emojiPicker(let action):
        return handleEmojiPickerAction(action, state: &state)
      case .activityTaskForm(let action):
        return handleActivityTaskFormAction(action, state: &state)
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$markerForm, action: \.markerForm) {
      MarkerFormFeature()
    }
    .ifLet(\.$emojiPicker, action: \.emojiPicker) {
      EmojiPickerFeature()
    }
    .ifLet(\.$activityTaskForm, action: \.activityTaskForm) {
      ActivityTaskFormFeature()
    }
  }

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .send(.internal(.loadTags))
    case .submitTagTapped:
      showNewTag(state: &state)
      return .none
    case .addTagButtonTapped:
      showNewTag(state: &state)
      return .none
    case .addedTagTapped(let tag):
      removeTag(tag, state: &state)
      return .send(.internal(.loadTags))
    case .existingTagTapped(let tag):
      appendTag(tag, state: &state)
      return .send(.internal(.loadTags))
    case .removeTagTapped(let tag):
      return .run { send in
        try await deleteTag(tag)
        await send(.internal(.loadTags))
      }
    case .iconTapped:
      state.emojiPicker = EmojiPickerFeature.State()
      return .none
    case .pickPhotoTapped:
      state.isPhotoPickerPresented = true
      return .none
    case .removeImageTapped:
      state.activity.icon = nil
      return .none
    case .saveButtonTapped:
      state.activity.startDate = today
      return .run { [activity = state.activity, type = state.type, tasks = state.tasksToRemove] send in
        for task in tasks {
          try await activityRepository.removeActivityTask(task)
        }
        try await activityRepository.saveActivity(activity)
        switch type {
        case .new:
          await send(.delegate(.activityCreated(activity)))
        case .edit:
          await send(.delegate(.activityUpdated(activity)))
        }
        await dismiss()
      }
    case .imageSelected(let item):
      return .run { send in
        let data = try await item.loadImageData(size: 140.0)
        await send(.internal(.setImageDate(data)))
      }
    case .addTaskButtonTapped:
      state.activityTaskForm = ActivityTaskFormFeature.State(
        activityTask: ActivityTask(
          id: uuid()
        ),
        type: .new
      )
      return .none
    case .editButtonTapped(let activityTask):
      state.activityTaskForm = ActivityTaskFormFeature.State(
        activityTask: activityTask,
        type: .edit
      )
      return .none
    case .removeButtonTapped(let activityTask):
      state.tasksToRemove.append(activityTask)
      state.activity.tasks.removeAll(where: { $0.id == activityTask.id })
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setExistingTags(let tags):
      state.existingTags = tags
      return .none
    case .loadTags:
      return .run { [enteredTags = state.activity.tags] send in
        let existingTags = try await loadTags(enteredTags)
        await send(.internal(.setExistingTags(existingTags)))
      }
    case .setImageDate(let imageData):
      state.activity.icon = Icon(
        id: uuid(),
        data: imageData
      )
      return .none
    }
  }

  private func handleMarkerFormAction(_ action: PresentationAction<MarkerFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.tagCreated(let tag))):
      state.newTag = .empty
      state.focus = nil
      appendTag(tag, state: &state)
      return .none
    case .presented, .dismiss:
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

  private func handleActivityTaskFormAction(_ action: PresentationAction<ActivityTaskFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityTask(let activityTask))):
      if let index = state.activity.tasks.firstIndex(where: { $0.id == activityTask.id }) {
        state.activity.tasks[index] = activityTask
      } else {
        state.activity.tasks.append(activityTask)
      }
      return .none
    case .presented, .dismiss:
      return .none
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
