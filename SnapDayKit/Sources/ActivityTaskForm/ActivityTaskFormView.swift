import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import EmojiPicker
import PhotosUI

@MainActor
public struct ActivityTaskFormView: View {

  // MARK: - Properties

  private let store: StoreOf<ActivityTaskFormFeature>
  @FocusState private var focus: ActivityTaskFormFeature.State.Field?
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )
  private func title(type: ActivityTaskFormFeature.ActivityTaskFormType) -> String {
    switch type {
    case .new:
      String(localized: "Add Activity Task", bundle: .module)
    case .edit:
      String(localized: "Edit Activity Task", bundle: .module)
    }
  }

  // MARK: - Initialization

  public init(store: StoreOf<ActivityTaskFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore: viewStore)
        .navigationTitle(title(type: viewStore.type))
    }
    .fullScreenCover(
      store: store.scope(
        state: \.$showEmojiPicker,
        action: { .showEmojiPicker($0) }
      ),
      content: { store in
        NavigationStack {
          EmojiPickerView(store: store)
        }
      }
    )
  }

  private func content(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    VStack(spacing: .zero) {
      formView(viewStore: viewStore)
        .padding(.bottom, 15.0)
      saveButton(viewStore: viewStore)
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
    .bind(viewStore.$focus, to: $focus)
  }

  private func formView(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    ScrollView {
      VStack(spacing: 15.0) {
        imageField(viewStore: viewStore)
        nameTextField(viewStore: viewStore)
        durationView(viewStore: viewStore)
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  private func imageField(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    Menu {
      Button(
        String(localized: "Select Emoji", bundle: .module),
        action: {
          viewStore.send(.view(.iconTapped))
        }
      )
      Button(
        String(localized: "Pick Photo", bundle: .module),
        action: {
          viewStore.send(.view(.pickPhotoTapped))
        }
      )
      Button(
        String(localized: "Remove", bundle: .module),
        action: {
          viewStore.send(.view(.removeImageTapped))
        }
      )
    } label: {
      HStack(spacing: 10.0) {
        ActivityImageView(
          data: viewStore.activityTask.icon?.data,
          size: 30.0,
          cornerRadius: 5.0,
          tintColor: .actionBlue
        )
        Text("Change icon", bundle: .module)
          .font(.system(size: 12.0, weight: .bold))
          .foregroundStyle(Color.actionBlue)
        Spacer()
      }
    }
    .formBackgroundModifier()
    .photosPicker(
      isPresented: viewStore.$isPhotoPickerPresented,
      selection: viewStore.binding(
        get: { state in state.photoItem?.photosPickerItem },
        send: { value in .view(.imageSelected(PhotoItem(photosPickerItem: value))) }
      ),
      matching: .images,
      preferredItemEncoding: .current,
      photoLibrary: .shared()
    )
  }

  private func nameTextField(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    FormTextField(
      title: String(localized: "Name", bundle: .module),
      placeholder: String(localized: "Enter name", bundle: .module),
      value: viewStore.$activityTask.name
    )
    .focused($focus, equals: .name)
  }

  private func durationView(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    ScrollViewReader { reader in
      VStack(alignment: .leading, spacing: 10.0) {
        Toggle(
          isOn: Binding(
            get: { viewStore.activityTask.isDefaultDuration },
            set: { viewStore.$activityTask.wrappedValue.setDefaultDuration($0) }
          )
        ) {
          Text(String(localized: "Default duration", bundle: .module))
            .formTitleTextStyle
        }
        .toggleStyle(CheckToggleStyle())
        if viewStore.activityTask.isDefaultDuration {
          DurationPickerView(
            selectedHours: Binding(
              get: { viewStore.activityTask.hours },
              set: { viewStore.$activityTask.wrappedValue.setDurationHours($0) }
            ),
            selectedMinutes: Binding(
              get: { viewStore.activityTask.minutes },
              set: { viewStore.$activityTask.wrappedValue.setDurationMinutes($0) }
            )
          )
          .scrollOnAppear("DurationView", anchor: .bottom, reader: reader)
        }
      }
      .formBackgroundModifier()
      .id("DurationView")
    }
  }

  private func saveButton(viewStore: ViewStoreOf<ActivityTaskFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.saveButtonTapped)) },
      label: { Text("Save", bundle: .module) }
    )
    .disabled(viewStore.isSaveButtonDisabled)
    .buttonStyle(PrimaryButtonStyle(disabled: viewStore.isSaveButtonDisabled))
  }
}
