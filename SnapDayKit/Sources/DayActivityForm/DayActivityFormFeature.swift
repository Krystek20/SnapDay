import ComposableArchitecture
import Common
import Models
import MarkerForm

public struct DayActivityFormFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.tagRepository) var tagRepository
  @Dependency(\.activityLabelRepository) var activityLabelRepository
  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.date) var date

  // MARK: - State & Action

  public struct State: Equatable {

    var existingTags: [Tag] = []
    var existingLabels: [ActivityLabel] = []

    var showAddTagButton: Bool { !newTag.isEmpty }
    var showAddLabelButton: Bool { !newLabel.isEmpty }
    @BindingState var dayActivity: DayActivity
    @BindingState var newTag = String.empty
    @BindingState var newLabel = String.empty
    @PresentationState var addMarker: MarkerFormFeature.State?

    public init(dayActivity: DayActivity) {
      self.dayActivity = dayActivity
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case saveButtonTapped
      case deleteButtonTapped
      
      case submitTagTapped
      case addTagButtonTapped
      case addedTagTapped(Tag)
      case existingTagTapped(Tag)
      case removeTagTapped(Tag)

      case submitLabelTapped
      case addLabelButtonTapped
      case addedLabelTapped(ActivityLabel)
      case existingLabelTapped(ActivityLabel)
      case removeLabelTapped(ActivityLabel)

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
        return .run(operation: { send in
          await send(.internal(.loadTags))
          await send(.internal(.loadLabels))
        })
      case .view(.saveButtonTapped):
        return .run { [activity = state.dayActivity] send in
          await send(.delegate(.activityUpdated(activity)))
          await dismiss()
        }
      case .view(.deleteButtonTapped):
        return .run { [activity = state.dayActivity] send in
          await send(.delegate(.activityDeleted(activity)))
          await dismiss()
        }
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
          try await tagRepository.deleteTag(tag)
          await send(.internal(.loadTags))
        }
      case .view(.isDoneToggleChanged(let value)):
        state.dayActivity.doneDate = value ? date() : nil
        return .none
      case .internal(.setExistingTags(let tags)):
        state.existingTags = tags
        return .none
      case .internal(.loadTags):
        return .run { [enteredTags = state.dayActivity.tags] send in
          let existingTags = try await tagRepository.loadTags(enteredTags)
          await send(.internal(.setExistingTags(existingTags)))
        }
      case .view(.submitLabelTapped):
        showNewLabel(state: &state)
        return .none
      case .view(.addLabelButtonTapped):
        showNewLabel(state: &state)
        return .none
      case .view(.addedLabelTapped(let label)):
        removeLabel(label, state: &state)
        return .send(.internal(.loadLabels))
      case .view(.existingLabelTapped(let label)):
        appendLabel(label, state: &state)
        return .send(.internal(.loadLabels))
      case .view(.removeLabelTapped(let label)):
        return .run { send in
          try await activityLabelRepository.deleteLabel(label)
          await send(.internal(.loadLabels))
        }
      case .internal(.setExistingLabels(let labels)):
        state.existingLabels = labels
        return .none
      case .internal(.loadLabels):
        return .run { [activity = state.dayActivity.activity, enteredLabels = state.dayActivity.labels] send in
          let existingLabels = try await activityLabelRepository.loadLabels(activity, enteredLabels)
          await send(.internal(.setExistingLabels(existingLabels)))
        }
      case .addMarker(.presented(.delegate(.tagCreated(let tag)))):
        state.newTag = .empty
        appendTag(tag, state: &state)
        return .none
      case .addMarker(.presented(.delegate(.labelCreated(let label)))):
        state.newLabel = .empty
        appendLabel(label, state: &state)
        state.dayActivity.activity.labels.append(label)
        return .run { [activity = state.dayActivity.activity] send in
          try await activityRepository.saveActivity(activity)
        }
      case .addMarker:
        return .none
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$addMarker, action: /Action.addMarker) {
      MarkerFormFeature()
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
