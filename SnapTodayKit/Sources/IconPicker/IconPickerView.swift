import SwiftUI
import ComposableArchitecture
import PhotosUI
import Resources
import UiComponents

@MainActor
public struct IconPickerView: View {

  // MARK: - Properties

  private let store: StoreOf<IconPickerFeature>
  private let columns = [
    GridItem(.adaptive(minimum: 50.0))
  ]
  @FocusState private var focus: IconPickerFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<IconPickerFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(alignment: .leading, spacing: 20.0) {
        titleSection
          .padding(.top, 5.0)
        photoPickerSection(viewStore: viewStore)
        emojiTextField(viewStore: viewStore)
        emojiGridView(viewStore: viewStore)
      }
      .padding(.horizontal, 15.0)
      .activityBackground
      .task {
        viewStore.send(.view(.appeared))
      }
      .bind(viewStore.$focus, to: $focus)
    }
  }

  @ViewBuilder
  private var titleSection: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text("Pick an emoji or select a photo to make your activity uniquely yours.", bundle: .module)
        .font(Fonts.Quicksand.regular.swiftUIFont(size: 12.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
        .fixedSize(horizontal: false, vertical: true)
      Divider().standard.padding(.top, 10.0)
    }
  }

  private func photoPickerSection(viewStore: ViewStoreOf<IconPickerFeature>) -> some View {
    ZStack {
      photoPicker(viewStore: viewStore)
        .disabled(viewStore.isLoadingPhoto)
        .opacity(viewStore.isLoadingPhoto ? 0.4 : 1.0)
      if viewStore.isLoadingPhoto {
        ProgressView()
      }
    }
  }

  private func photoPicker(viewStore: ViewStoreOf<IconPickerFeature>) -> some View {
    PhotosPicker(
      selection: viewStore.binding(
        get: { state in
          state.photoItem?.photosPickerItem
        }, send: { value in
          .view(.imageSelected(PhotoItem(photosPickerItem: value)))
        }
      ),
      matching: .images,
      preferredItemEncoding: .current,
      photoLibrary: .shared(),
      label: { iconPickerLabel }
    )
    .setCompactStyleIfPossible()
  }

  private var iconPickerLabel: some View {
    HStack(spacing: 5.0) {
      Image(systemName: "photo")
      Text("Select from gallery", bundle: .module)
        .font(Fonts.Quicksand.medium.swiftUIFont(size: 12.0))
    }
    .foregroundStyle(Colors.actionBlue.swiftUIColor)
  }

  private func emojiTextField(viewStore: ViewStoreOf<IconPickerFeature>) -> some View {
    FormTextField(
      placeholder: String(localized: "Search emoji", bundle: .module),
      value: viewStore.$searchText
    )
    .focused($focus, equals: .searchEmoji)
  }

  private func emojiGridView(viewStore: ViewStoreOf<IconPickerFeature>) -> some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 10.0) {
        ForEach(viewStore.emoji) { group in
          Section {
            ForEach(group.subgroups) { subgroup in
              Section {
                ForEach(subgroup.items) { item in
                  Text(item.emoji)
                    .font(.system(size: 36.0))
                    .onTapGesture {
                      viewStore.send(.view(.emojiSelected(item)))
                    }
                }
              }
            }
          } header: {
            Text(LocalizedStringKey(group.name), bundle: .module)
              .formTitleTextStyle
              .maxWidth(alignment: .leading)
          }
        }
      }
    }
    .scrollIndicators(.hidden)
    .scrollDismissesKeyboard(.immediately)
  }
}

private extension View {
  func setCompactStyleIfPossible() -> some View {
    if #available(iOS 17.0, *) {
      return self
        .photosPickerStyle(.compact)
        .photosPickerDisabledCapabilities(.selectionActions)
        .photosPickerAccessoryVisibility(.hidden, edges: .all)
        .ignoresSafeArea()
        .frame(height: 100.0)
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    }
    return self
  }
}
