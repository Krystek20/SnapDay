import Foundation
import ComposableArchitecture
import Common
import SwiftUI

public struct IconPickerFeature: Reducer {

  // MARK: - Dependecies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {

    public enum Field: Hashable {
      case searchEmoji
    }

    @BindingState var searchText = String.empty
    @BindingState var focus: Field?
    var loadedEmoji: [EmojiGroup] = []
    var emoji: [EmojiGroup] = []
    var photoItem: PhotoItem?
    var isLoadingPhoto: Bool = false

    public init(focus: Field? = nil) {
      self.focus = focus
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable { 
      case appeared
      case imageSelected(PhotoItem)
      case emojiSelected(Emoji)
    }
    public enum InternalAction: Equatable { 
      case emojiPrepared([EmojiGroup])
      case imageLoadingChanged(isLoading: Bool)
    }
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
      case .view(.appeared):
        return .run { send in
          let emoji = try EmojiProvider().emoji
          await send(.internal(.emojiPrepared(emoji)))
        }
      case .view(.imageSelected(let item)):
        return .run { send in
          await send(.internal(.imageLoadingChanged(isLoading: true)))
          let data = try await item.loadImageData(size: 140.0)
          await send(.internal(.imageLoadingChanged(isLoading: false)))
          await send(.delegate(.dataSelected(data)))
          await dismiss()
        }
      case .view(.emojiSelected(let item)):
        return .run { send in
          let data = item.emoji.emojiToImage(size: 140.0).pngData()
          await send(.delegate(.dataSelected(data)))
          await dismiss()
        }
      case .internal(.emojiPrepared(let emoji)):
        state.loadedEmoji = emoji
        state.emoji = emoji
        return .none
      case .internal(.imageLoadingChanged(let isLoading)):
        state.isLoadingPhoto = isLoading
        return .none
      case .delegate(.dataSelected):
        state.focus = nil
        return .none
      case .delegate:
        return .none
      case .binding(\.$searchText):
        state.emoji = state.searchText.isEmpty
        ? state.loadedEmoji
        : state.loadedEmoji.filter(by: state.searchText)
        return .none
      case .binding:
        return .none
      }
    }
  }
}
