import Foundation
import ComposableArchitecture
import Common

public struct EmojiPickerFeature: Reducer {

  // MARK: - Dependecies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {

    public enum Field: Hashable {
      case searchEmoji
    }

    @BindingState var focus: Field?
    @BindingState var emoji: String = ""

    public init(focus: Field? = .searchEmoji) {
      self.focus = focus
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case saveButtonTapped
      case cancelButtonTapped
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case dataSelected(Data?)
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
      case .view(.saveButtonTapped):
        return .run { [emoji = state.emoji] send in
          let data = emoji.isEmpty 
          ? nil
          : emoji.emojiToImage(size: 140.0).pngData()
          await send(.delegate(.dataSelected(data)))
          await dismiss()
        }
      case .view(.cancelButtonTapped):
        return .run { send in
          await dismiss()
        }
      case .delegate(.dataSelected):
        state.focus = nil
        return .none
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
  }
}
