import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct EmojiPickerView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<EmojiPickerFeature>
  @FocusState private var focus: EmojiPickerFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<EmojiPickerFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 20.0) {
      titleSection
        .padding(.top, 5.0)
      emojiTextField
    }
    .padding(.horizontal, 15.0)
    .activityBackground
    .bind($store.focus, to: $focus)
    .navigationTitle(String(localized: "Set Your Activity Emoji", bundle: .module))
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(String(localized: "Save", bundle: .module)) {
          store.send(.view(.saveButtonTapped))
        }
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
      }
      ToolbarItem(placement: .topBarLeading) {
        Button(String(localized: "Cancel", bundle: .module)) {
          store.send(.view(.cancelButtonTapped))
        }
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
      }
    }
  }

  private var titleSection: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text("Pick an emoji to make your activity uniquely yours.", bundle: .module)
        .font(.system(size: 12.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
        .fixedSize(horizontal: false, vertical: true)
      Divider().standard.padding(.top, 10.0)
    }
  }

  private var emojiTextField: some View {
    EmojiTextField(text: $store.emoji)
      .focused($focus, equals: .searchEmoji)
  }
}
