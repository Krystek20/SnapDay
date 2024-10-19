import Foundation
import ComposableArchitecture
import Common
import Models
import MarkerForm
import EmojiPicker
import Utilities
import UIKit.UIApplication

@Reducer
public struct DayActivityFormFeature {

  // MARK: - Dependencies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.activityLabelRepository) private var activityLabelRepository
  @Dependency(\.date) private var date
  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar
  @Dependency(\.openURL) private var openURL
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    public enum DayActivityFormType {
      case edit
    }

    public enum Field: Hashable {
      case name
      case tag
      case newTask
    }

    var form: DayActivityForm
    var focus: Field?

    var existingTags: [Tag] = []
    var existingLabels: [ActivityLabel] = []

    var showAddTagButton: Bool { !newTag.isEmpty }
    var showAddLabelButton: Bool { !newLabel.isEmpty }

    var title: String {
      switch type {
      case .edit:
        form.editTitle
      }
    }

    var showEnableNotificationButton: Bool = false

    var canShowDateForms: Bool {
      editDate >= today && !form.completed
    }

    var weekdays: [Weekday] {
      @Dependency(\.calendar) var calendar
      return WeekdaysProvider(calendar: calendar).weekdays
    }

    let type: DayActivityFormType
    var newTag = String.empty
    var newLabel = String.empty

    var isPhotoPickerPresented: Bool = false
    var photoItem: PhotoItem?
    var editDate: Date

    var showFrequencyOptions: Bool { form.frequency != nil }
    var showWeekdaysView: Bool { form.areWeekdaysRequried }
    var showMonthlyView: Bool { form.areMonthlyScheduleRequried }
    var showMonthDays: Bool { form.areMonthDaysRequried }
    var showMonthWeekdays: Bool { form.areMonthWeekdaysRequried }
    var isSaveButtonDisabled: Bool { !form.validated }

    var newActivityTask = DayNewActivityTask.empty

    @Presents var emojiPicker: EmojiPickerFeature.State?
    @Presents var addMarker: MarkerFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityFormFeature.State?

    public init(
      form: DayActivityForm,
      type: DayActivityFormType,
      editDate: Date
    ) {
      self.form = form
      self.type = type
      self.editDate = editDate
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
        case selectButtonTapped(DayActivityForm)
        case editButtonTapped(DayActivityForm)
        case removeButtonTapped(DayActivityForm)
        case newActivityActionPerformed(DayNewActivityAction)
      }

      case appeared
      case tag(TagAction)
      case label(LabelAction)
      case task(TaskAction)
      case saveButtonTapped
      case deleteButtonTapped
      case iconTapped
      case pickPhotoTapped
      case removeImageTapped
      case imageSelected(PhotoItem)
      case remindToggeled(Bool)
      case dueTimeToggeled(Bool)
      case turnNotificationTapped
    }
    public enum InternalAction: Equatable {
      case setExistingTags([Tag])
      case loadTags
      case setExistingLabels([ActivityLabel])
      case loadLabels
      case setImageDate(_ date: Data?)
      case determineNotificationStatus
      case handleNotificationStatus(UserNotificationCenterProvider.Status)
    }
    public enum DelegateAction: Equatable {
      case activityDeleted(DayActivityForm)
      case activityUpdated(DayActivityForm)
    }

    case emojiPicker(PresentationAction<EmojiPickerFeature.Action>)
    case addMarker(PresentationAction<MarkerFormFeature.Action>)
    case dayActivityTaskForm(PresentationAction<DayActivityFormFeature.Action>)

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
      case .addMarker(let presentableMarkerAction):
        handleAddMarker(presentableMarkerAction, state: &state)
      case .dayActivityTaskForm(let presentableDayActivityTaskFormAction):
        handleDayActivityTaskForm(presentableDayActivityTaskFormAction, state: &state)
      case .binding(\.form):
        handleCompleted(state: &state)
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
    .ifLet(\.$emojiPicker, action: \.emojiPicker) {
      EmojiPickerFeature()
    }
    .ifLet(\.$addMarker, action: \.addMarker) {
      MarkerFormFeature()
    }
    .ifLet(\.$dayActivityTaskForm, action: \.dayActivityTaskForm) {
      DayActivityFormFeature()
    }
  }

  func handleCompleted(state: inout State) -> Effect<Action> {
    if state.form.completed && state.form.reminderDate != nil {
      state.form.reminderDate = nil
    }
    if state.form.completed && state.form.dueDate != nil {
      state.form.dueDate = nil
    }
    return .none
  }

  func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .merge(
        .send(.internal(.determineNotificationStatus)),
        .run { send in
          await send(.internal(.loadTags))
          await send(.internal(.loadLabels))
        }
      )
    case .saveButtonTapped:
      return .run { [form = state.form, type = state.type] send in
        switch type {
        case .edit:
          await send(.delegate(.activityUpdated(form)))
        }
        await dismiss()
      }
    case .deleteButtonTapped:
      return .run { [form = state.form] send in
        await send(.delegate(.activityDeleted(form)))
        await dismiss()
      }
    case .tag(let tagAction):
      return handleViewTagAction(tagAction, state: &state)
    case .label(let labelAction):
      return handleViewLabelAction(labelAction, state: &state)
    case .task(let taskAction):
      return handleViewTaskAction(taskAction, state: &state)
    case .iconTapped:
      state.emojiPicker = EmojiPickerFeature.State()
      return .none
    case .pickPhotoTapped:
      state.isPhotoPickerPresented = true
      return .none
    case .removeImageTapped:
      state.form.icon = nil
      return .none
    case .imageSelected(let item):
      return .run { send in
        let data = try await item.loadImageData(size: 140.0)
        await send(.internal(.setImageDate(data)))
      }
    case .remindToggeled(let value):
      state.form.reminderDate = value
      ? calendar.setHourAndMinute(date.now, toDate: state.editDate)
      : nil
      return .none
    case .dueTimeToggeled(let value):
      state.form.dueDate = value
      ? calendar.dayFormat(state.editDate)
      : nil
      return .none
    case .turnNotificationTapped:
      return .run { send in
        switch await userNotificationCenterProvider.status {
        case .notDetermined:
          let result = try await userNotificationCenterProvider.requestAuthorization()
          guard result else { return }
          await send(.internal(.determineNotificationStatus))
        case .denied:
          guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
          await openURL(settingsURL)
        case .authorized:
          return
        }
      }
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
      state.newActivityTask.activityId = state.form.id
      state.newActivityTask.isFormVisible = true
      state.focus = .newTask
      return .none
    case .selectButtonTapped(let dayActivityTaskForm):
      state.form.tasks.firstIndex(where: { $0.id == dayActivityTaskForm.id }).map { index in
        state.form.tasks[index].completed.toggle()
      }
      return .none
    case .editButtonTapped(let dayActivityTaskForm):
      state.dayActivityTaskForm = DayActivityFormFeature.State(
        form: dayActivityTaskForm,
        type: .edit,
        editDate: state.editDate
      )
      return .none
    case .removeButtonTapped(let dayActivityTaskForm):
      guard let index = state.form.tasks.firstIndex(where: { $0.id == dayActivityTaskForm.id }) else { return .none }
      state.form.tasks.remove(at: index)
      return .none
    case .newActivityActionPerformed(.dayActivityTask(let action)):
      switch action {
      case .cancelled:
        state.newActivityTask = .empty
        state.focus = nil
        return .none
      case .submitted:
        let name = state.newActivityTask.name
        state.newActivityTask = .empty
        state.focus = nil
        guard !name.isEmpty, var taskForm = state.form.newTaskForm(newId: uuid()) else { return .none }
        taskForm.name = name
        state.form.tasks.append(taskForm)
        return .none
      }
    case .newActivityActionPerformed(.dayActivity):
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setExistingTags(let tags):
      state.existingTags = tags
      return .none
    case .loadTags:
      return .run { [enteredTags = state.form.tags] send in
        let existingTags = try await tagRepository.loadTags(enteredTags)
        await send(.internal(.setExistingTags(existingTags)))
      }
    case .setExistingLabels(let labels):
      state.existingLabels = labels
      return .none
    case .loadLabels:
      guard let parentId = state.form.ids[.templateId] else { return .none }
      return .run { [parentId, enteredLabels = state.form.labels] send in
        let existingLabels = try await activityLabelRepository.loadLabels(parentId, enteredLabels)
        await send(.internal(.setExistingLabels(existingLabels)))
      }
    case .setImageDate(let imageData):
      state.form.icon = Icon(
        id: uuid(),
        data: imageData
      )
      return .none
    case .determineNotificationStatus:
      return .run { send in
        await send(.internal(.handleNotificationStatus(userNotificationCenterProvider.status)))
      }
    case .handleNotificationStatus(let status):
      state.showEnableNotificationButton = switch status {
      case .notDetermined, .denied:
        true
      case .authorized:
        false
      }
      return .none
    }
  }

  private func handleEmojiPickerAction(_ action: PresentationAction<EmojiPickerFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dataSelected(let data))):
      .send(.internal(.setImageDate(data)))
    case .presented, .dismiss:
      .none
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
      return .none
    default:
      return .none
    }
  }

  func handleDayActivityTaskForm(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityDeleted(let dayActivityTaskForm))):
      state.form.tasks.removeAll(where: { $0.id == dayActivityTaskForm.id })
      return .none
    case .presented(.delegate(.activityUpdated(let dayActivityTaskForm))):
      state.form.tasks.firstIndex(where: { $0.id == dayActivityTaskForm.id }).map { index in
        state.form.tasks[index] = dayActivityTaskForm
      }
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
    guard !state.form.tags.contains(where: { $0.name == tag.name }) else { return }
    state.form.tags.append(tag)
  }

  private func removeTag(_ tag: Tag, state: inout State) {
    guard state.form.tags.contains(where: { $0.name == tag.name }) else { return }
    state.form.tags.removeAll(where: { $0.name == tag.name })
  }

  private func showNewLabel(state: inout State) {
    guard !state.newLabel.isEmpty, let templateId = state.form.ids[.templateId] else { return }
    state.addMarker = MarkerFormFeature.State(
      markerType: .label(activityId: templateId),
      name: state.newLabel
    )
  }

  private func appendLabel(_ label: ActivityLabel, state: inout State) {
    guard !state.form.labels.contains(where: { $0.name == label.name }) else { return }
    state.form.labels.append(label)
  }

  private func removeLabel(_ label: ActivityLabel, state: inout State) {
    guard state.form.labels.contains(where: { $0.name == label.name }) else { return }
    state.form.labels.removeAll(where: { $0.name == label.name })
  }
}
