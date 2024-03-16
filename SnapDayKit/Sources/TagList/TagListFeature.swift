import ComposableArchitecture
import Repositories
import Models
import Common

public struct TagListFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {
    var tag: Tag
    var days: [Day]
    var tags: [Tag]

    var availableTags: [Tag] {
      tags.filter { tag in
        days.contains(where: { $0.activities.contains(where: { $0.activity.tags.contains(tag) }) })
      }
    }

    public init(tag: Tag, tags: [Tag], days: [Day]) {
      self.tag = tag
      self.tags = tags
      self.days = days
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case tagSelected(Tag)
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case tagSelected(Tag)
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
      case .view(.tagSelected(let tag)):
        return .run { send in
          await send(.delegate(.tagSelected(tag)))
          await dismiss()
        }
      case .binding:
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
