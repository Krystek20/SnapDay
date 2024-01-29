import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct EmojiPickerView: View {

  // MARK: - Properties

  private let store: StoreOf<EmojiPickerFeature>
  @FocusState private var focus: EmojiPickerFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<EmojiPickerFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(alignment: .leading, spacing: 20.0) {
        titleSection
          .padding(.top, 5.0)
        emojiTextField(viewStore: viewStore)
      }
      .padding(.horizontal, 15.0)
      .activityBackground
      .bind(viewStore.$focus, to: $focus)
      .navigationTitle(String(localized: "Set Your Activity Emoji", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(String(localized: "Save", bundle: .module)) {
            viewStore.send(.view(.saveButtonTapped))
          }
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
          .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
        }
        ToolbarItem(placement: .topBarLeading) {
          Button(String(localized: "Cancel", bundle: .module)) {
            viewStore.send(.view(.cancelButtonTapped))
          }
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
          .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
        }
      }
    }
  }

  private var titleSection: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text("Pick an emoji to make your activity uniquely yours.", bundle: .module)
        .font(Fonts.Quicksand.regular.swiftUIFont(size: 12.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
        .fixedSize(horizontal: false, vertical: true)
      Divider().standard.padding(.top, 10.0)
    }
  }

  private func emojiTextField(viewStore: ViewStoreOf<EmojiPickerFeature>) -> some View {
    EmojiTextField(text: viewStore.$emoji)
      .focused($focus, equals: .searchEmoji)
  }
}
