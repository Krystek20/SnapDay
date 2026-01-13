import Foundation
import ComposableArchitecture
import Common
import Models
import MarkerForm
import EmojiPicker
import Utilities
import UIKit.UIApplication

import struct UiComponents.ListItem
import enum UiComponents.ListItemAction

@Reducer
public struct DayActivityFormFeature {

  // MARK: - Dependencies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.iconRepository) private var iconRepository
  @Dependency(\.activityLabelRepository) private var activityLabelRepository
  @Dependency(\.date) private var date
  @Dependency(\.uuid) private var uuid
  @Dependency(\.utcCalendar) private var utcCalendar
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

    var newField: DayNewField?
    var items: [ListItem] = []
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
      WeekdaysProvider().weekdays
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
        case listItemActionPerfomed(ListItemAction)
      }

      case appeared
      case tag(TagAction)
      case label(LabelAction)
      case task(TaskAction)
      case saveButtonTapped
      case deleteButtonTapped
      case cancelButtonTapped
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
      case saveIconDate(_ date: Data?)
      case setIconId(_ identifier: UUID?)
      case determineNotificationStatus
      case handleNotificationStatus(UserNotificationCenterProvider.Status)
      case setItems
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
          await send(.internal(.setItems))
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
    case .cancelButtonTapped:
      return .run { _ in
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
      state.form.iconId = nil
      return .none
    case .imageSelected(let item):
      return .run { send in
        do {
          let data = try await item.loadImageData(size: 140.0)
          await send(.internal(.saveIconDate(data)))
        } catch {
          print("cannot create data from image: \(error)")
        }
      }
    case .remindToggeled(let value):
      state.form.reminderDate = value
      ? calendar.setHourAndMinute(date.now, toDate: state.editDate)
      : nil
      return .none
    case .dueTimeToggeled(let value):
      state.form.dueDate = value
      ? utcCalendar.dayFormat(state.editDate)
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
      state.newField = .taskName(identifier: state.form.id.uuidString)
      state.focus = .newTask
      return .send(.internal(.setItems))
    case .listItemActionPerfomed(let action):
      switch action {
      case .reorder, .rowAction:
        return .none
      case .itemTapped(let itemId, _):
        guard let form = state.form.tasks.first(where: { $0.id.uuidString == itemId }) else { return .none }
        state.dayActivityTaskForm = DayActivityFormFeature.State(
          form: form,
          type: .edit,
          editDate: state.editDate
        )
        return .none
      case .newItemForm(.cancelled):
        state.newField = nil
        state.focus = nil
        return .send(.internal(.setItems))
      case .newItemForm(.submitted):
        guard let item = state.items.first(where: { $0.isForm }),
              item.title != .empty,
              var taskForm = state.form.newTaskForm(newId: uuid()) else {
          return handleViewTaskAction(.listItemActionPerfomed(.newItemForm(.cancelled)), state: &state)
        }
        state.newField = nil
        state.focus = nil
        taskForm.name = item.title
        state.form.tasks.append(taskForm)
        return .send(.internal(.setItems))
      case .menuAction(let menuParameters, _):
        guard let form = state.form.tasks.first(where: { $0.id.uuidString == menuParameters.itemId }),
              let action = DayActivityFormAction(rawValue: menuParameters.actionId) else { return .none }
        switch action {
        case .select:
          state.form.tasks.firstIndex(where: { $0.id == form.id }).map { index in
            state.form.tasks[index].completed = true
          }
          return .send(.internal(.setItems))
        case .deselect:
          state.form.tasks.firstIndex(where: { $0.id == form.id }).map { index in
            state.form.tasks[index].completed = false
          }
          return .send(.internal(.setItems))
        case .edit:
          state.dayActivityTaskForm = DayActivityFormFeature.State(
            form: form,
            type: .edit,
            editDate: state.editDate
          )
          return .none
        case .remove:
          state.form.tasks.removeAll(where: { $0.id == form.id })
          return .send(.internal(.setItems))
        }
      }
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
    case .saveIconDate(let imageData):
      if let imageData {
        let icon = Icon(
          id: uuid(),
          data: imageData,
          lastUpdated: date.now
        )
        return .run { [icon] send in
          try await iconRepository.saveIcon(icon)
          await send(.internal(.setIconId(icon.id)))
        }
      } else {
        return .run { send in
          await send(.internal(.setIconId(nil)))
        }
      }
    case .setIconId(let iconId):
      state.form.iconId = iconId
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
    case .setItems:
      state.items = ListItemsBuilder(tasks: state.form.tasks, newField: state.newField).build()
      return .none
    }
  }

  private func handleEmojiPickerAction(_ action: PresentationAction<EmojiPickerFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dataSelected(let data))):
      .send(.internal(.saveIconDate(data)))
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
      return .send(.internal(.setItems))
    case .presented(.delegate(.activityUpdated(let dayActivityTaskForm))):
      state.form.tasks.firstIndex(where: { $0.id == dayActivityTaskForm.id }).map { index in
        state.form.tasks[index] = dayActivityTaskForm
      }
      return .send(.internal(.setItems))
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
