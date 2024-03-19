import ComposableArchitecture
import Common
import Models
import TagForm

public struct DayActivityFormFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.tagRepository) var tagRepository

  // MARK: - State & Action

  public struct State: Equatable {

    var existingTags = [Tag]()
    var showAddTagButton: Bool { !newTag.isEmpty }
    @BindingState var dayActivity: DayActivity
    @BindingState var newTag = String.empty
    @PresentationState var addTag: TagFormFeature.State?

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
    }
    public enum InternalAction: Equatable { 
      case setExistingTags([Tag])
      case loadTags
    }
    public enum DelegateAction: Equatable {
      case activityDeleted(DayActivity)
      case activityUpdated(DayActivity)
    }

    case addTag(PresentationAction<TagFormFeature.Action>)

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
      case .internal(.setExistingTags(let tags)):
        state.existingTags = tags
        return .none
      case .internal(.loadTags):
        return .run { [enteredTags = state.dayActivity.tags] send in
          let existingTags = try await tagRepository.loadTags(enteredTags)
          await send(.internal(.setExistingTags(existingTags)))
        }
      case .addTag(.presented(.delegate(.tagCreated(let tag)))):
        state.newTag = .empty
        appendTag(tag, state: &state)
        return .none
      case .addTag:
        return .none
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$addTag, action: /Action.addTag) {
      TagFormFeature()
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
    guard !state.dayActivity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.dayActivity.tags.append(tag)
  }

  private func removeTag(_ tag: Tag, state: inout State) {
    guard state.dayActivity.tags.contains(where: { $0.name == tag.name }) else { return }
    state.dayActivity.tags.removeAll(where: { $0.name == tag.name })
  }
}
