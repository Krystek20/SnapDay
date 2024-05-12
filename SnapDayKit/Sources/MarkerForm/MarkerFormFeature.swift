import ComposableArchitecture
import Repositories
import Models
import Common

@Reducer
public struct MarkerFormFeature {

  public enum MarkerType: Equatable {
    case tag
    case label
  }

  // MARK: - Dependencies

  @Dependency(\.tagRepository.saveTag) var saveTag
  @Dependency(\.activityLabelRepository.saveLabel) var saveLabel
  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var title: String {
      switch markerType {
      case .tag:
        String(localized: "Add Tag", bundle: .module)
      case .label:
        String(localized: "Add Label", bundle: .module)
      }
    }

    var markerType: MarkerType
    var name: String
    var color: RGBColor = .random

    public init(markerType: MarkerType, name: String = "") {
      self.markerType = markerType
      self.name = name
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case saveButtonTapped
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case tagCreated(Tag)
      case labelCreated(ActivityLabel)
    }

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
      case .binding:
        return .none
      case .view(.saveButtonTapped):
        return .run { [markerType = state.markerType, name = state.name, color = state.color] send in
          switch markerType {
          case .tag:
            let tag = Tag(name: name, color: color)
            try await saveTag(tag)
            await send(.delegate(.tagCreated(tag)))
          case .label:
            let label = ActivityLabel(name: name, color: color)
            try await saveLabel(label)
            await send(.delegate(.labelCreated(label)))
          }
          await dismiss()
        }
      case .delegate:
        return .none
      }
    }
  }
}
