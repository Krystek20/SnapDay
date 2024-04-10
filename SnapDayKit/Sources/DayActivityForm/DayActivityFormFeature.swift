import ComposableArchitecture
import Common
import Models
import MarkerForm
import DayActivityTaskForm

@Reducer
public struct DayActivityFormFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.tagRepository) var tagRepository
  @Dependency(\.activityLabelRepository) var activityLabelRepository
  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.date) var date
  @Dependency(\.uuid) var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var existingTags: [Tag] = []
    var existingLabels: [ActivityLabel] = []

    var showAddTagButton: Bool { !newTag.isEmpty }
    var showAddLabelButton: Bool { !newLabel.isEmpty }
    
    var dayActivity: DayActivity
    var newTag = String.empty
    var newLabel = String.empty
    
    @Presents var addMarker: MarkerFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityTaskFormFeature.State?

    public init(dayActivity: DayActivity) {
      self.dayActivity = dayActivity
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      public enum TagAction: Equatable {
        case submitTapped
        case addButtonTapped
        case addedTapped(Tag)
        case existingTapped(Tag)
        case removeTapped(Tag)
      }

      public enum LabelAction: Equatable {
        case submitTapped
        case addButtonTapped
        case addedTapped(ActivityLabel)
        case existingTapped(ActivityLabel)
        case removeTapped(ActivityLabel)
      }

      public enum TaskAction: Equatable {
        case addButtonTapped
        case selectButtonTapped(DayActivityTask)
        case editButtonTapped(DayActivityTask)
        case removeButtonTapped(DayActivityTask)
      }

      case appeared
      case tag(TagAction)
      case label(LabelAction)
      case task(TaskAction)
      case saveButtonTapped
      case deleteButtonTapped
      case isDoneToggleChanged(Bool)
    }
    public enum InternalAction: Equatable { 
      case setExistingTags([Tag])
      case loadTags
      case setExistingLabels([ActivityLabel])
      case loadLabels
    }
    public enum DelegateAction: Equatable {
      case activityDeleted(DayActivity)
      case activityUpdated(DayActivity)
    }

    case addMarker(PresentationAction<MarkerFormFeature.Action>)
    case dayActivityTaskForm(PresentationAction<DayActivityTaskFormFeature.Action>)

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
      case .addMarker(let presentableMarkerAction):
        handleAddMarker(presentableMarkerAction, state: &state)
      case .dayActivityTaskForm(let presentableDayActivityTaskFormAction):
        handleDayActivityTaskForm(presentableDayActivityTaskFormAction, state: &state)
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
    .ifLet(\.$addMarker, action: \.addMarker) {
      MarkerFormFeature()
    }
    .ifLet(\.$dayActivityTaskForm, action: \.dayActivityTaskForm) {
      DayActivityTaskFormFeature()
    }
  }

  func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .run(operation: { send in
        await send(.internal(.loadTags))
        await send(.internal(.loadLabels))
      })
    case .saveButtonTapped:
      return .run { [activity = state.dayActivity] send in
        await send(.delegate(.activityUpdated(activity)))
        await dismiss()
      }
    case .deleteButtonTapped:
      return .run { [activity = state.dayActivity] send in
        await send(.delegate(.activityDeleted(activity)))
        await dismiss()
      }
    case .tag(let tagAction):
      return handleViewTagAction(tagAction, state: &state)
    case .label(let labelAction):
      return handleViewLabelAction(labelAction, state: &state)
    case .task(let taskAction):
      return handleViewTaskAction(taskAction, state: &state)
    case .isDoneToggleChanged(let value):
      state.dayActivity.doneDate = value ? date() : nil
      return .none
    }
  }

  private func handleViewTagAction(_ action: Action.ViewAction.TagAction, state: inout State) -> Effect<Action> {
    switch action {
    case .submitTapped:
      showNewTag(state: &state)
      return .none
    case .addButtonTapped:
      showNewTag(state: &state)
      return .none
    case .addedTapped(let tag):
      removeTag(tag, state: &state)
      return .send(.internal(.loadTags))
    case .existingTapped(let tag):
      appendTag(tag, state: &state)
      return .send(.internal(.loadTags))
    case .removeTapped(let tag):
      return .run { send in
        try await tagRepository.deleteTag(tag)
        await send(.internal(.loadTags))
      }
    }
  }

  private func handleViewLabelAction(_ action: Action.ViewAction.LabelAction, state: inout State) -> Effect<Action> {
    switch action {
    case .submitTapped:
      showNewLabel(state: &state)
      return .none
    case .addButtonTapped:
      showNewLabel(state: &state)
      return .none
    case .addedTapped(let activityLabel):
      removeLabel(activityLabel, state: &state)
      return .send(.internal(.loadLabels))
    case .existingTapped(let activityLabel):
      appendLabel(activityLabel, state: &state)
      return .send(.internal(.loadLabels))
    case .removeTapped(let activityLabel):
      return .run { send in
        try await activityLabelRepository.deleteLabel(activityLabel)
        await send(.internal(.loadLabels))
      }
    }
  }

  private func handleViewTaskAction(_ action: Action.ViewAction.TaskAction, state: inout State) -> Effect<Action> {
    switch action {
    case .addButtonTapped:
      state.dayActivityTaskForm = DayActivityTaskFormFeature.State(
        dayActivityTask: DayActivityTask(id: uuid()),
        type: .new
      )
      return .none
    case .selectButtonTapped(let dayActivityTask):
      guard let index = state.dayActivity.dayActivityTasks.firstIndex(where: { $0.id ==  dayActivityTask.id }) else { return .none }
      state.dayActivity.dayActivityTasks[index].doneDate = dayActivityTask.doneDate == nil ? date() : nil
      return .none
    case .editButtonTapped(let dayActivityTask):
      state.dayActivityTaskForm = DayActivityTaskFormFeature.State(
        dayActivityTask: dayActivityTask,
        type: .edit
      )
      return .none
    case .removeButtonTapped(let dayActivityTask):
      guard let index = state.dayActivity.dayActivityTasks.firstIndex(where: { $0.id ==  dayActivityTask.id }) else { return .none }
      state.dayActivity.dayActivityTasks.remove(at: index)
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setExistingTags(let tags):
      state.existingTags = tags
      return .none
    case .loadTags:
      return .run { [enteredTags = state.dayActivity.tags] send in
        let existingTags = try await tagRepository.loadTags(enteredTags)
        await send(.internal(.setExistingTags(existingTags)))
      }
    case .setExistingLabels(let labels):
      state.existingLabels = labels
      return .none
    case .loadLabels:
      return .run { [activity = state.dayActivity.activity, enteredLabels = state.dayActivity.labels] send in
        let existingLabels = try await activityLabelRepository.loadLabels(activity, enteredLabels)
        await send(.internal(.setExistingLabels(existingLabels)))
      }
    }
  }

  private func handleAddMarker(_ action: PresentationAction<MarkerFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.tagCreated(let tag))):
      state.newTag = .empty
      appendTag(tag, state: &state)
      return .none
    case .presented(.delegate(.labelCreated(let label))):
      state.newLabel = .empty
      appendLabel(label, state: &state)
      state.dayActivity.activity.labels.append(label)
      return .run { [activity = state.dayActivity.activity] send in
        try await activityRepository.saveActivity(activity)
      }
    default:
      return .none
    }
  }

  func handleDayActivityTaskForm(_ action: PresentationAction<DayActivityTaskFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dayActivityTaskDeleted(let dayActivityTask))):
      state.dayActivity.dayActivityTasks.removeAll(where: { $0.id ==  dayActivityTask.id })
      return .none
    case .presented(.delegate(.dayActivityTaskUpdated(let dayActivityTask))):
      guard let index = state.dayActivity.dayActivityTasks.firstIndex(where: { $0.id == dayActivityTask.id }) else { return .none }
      state.dayActivity.dayActivityTasks[index] = dayActivityTask
      return .none
    case .presented(.delegate(.dayActivityTaskCreated(let dayActivityTask))):
      state.dayActivity.dayActivityTasks.append(dayActivityTask)
      return .none
    default:
      return .none
    }
  }

  // MARK: - Private

  private func showNewTag(state: inout State) {
    guard !state.newTag.isEmpty else { return }
    state.addMarker = MarkerFormFeature.State(
      markerType: .tag,
      name: state.newTag
    )
  }

  private func appendTag(_ tag: Tag, state: inout State) {
    guard !state.dayActivity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.dayActivity.tags.append(tag)
  }

  private func removeTag(_ tag: Tag, state: inout State) {
    guard state.dayActivity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.dayActivity.tags.removeAll(where: { $0.name == tag.name })
  }

  private func showNewLabel(state: inout State) {
    guard !state.newLabel.isEmpty else { return }
    state.addMarker = MarkerFormFeature.State(
      markerType: .label,
      name: state.newLabel
    )
  }

  private func appendLabel(_ label: ActivityLabel, state: inout State) {
    guard !state.dayActivity.labels.contains(where: { $0.name == label.name }) else { return }
    state.dayActivity.labels.append(label)
  }

  private func removeLabel(_ label: ActivityLabel, state: inout State) {
    guard state.dayActivity.labels.contains(where: { $0.name == label.name }) else { return }
    state.dayActivity.labels.removeAll(where: { $0.name == label.name })
  }
}
