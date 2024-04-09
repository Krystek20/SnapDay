import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import MarkerForm
import EmojiPicker

@MainActor
public struct DayActivityTaskFormView: View {

  // MARK: - Properties

  private let store: StoreOf<DayActivityTaskFormFeature>
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )

  // MARK: - Initialization

  public init(store: StoreOf<DayActivityTaskFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore: viewStore)
        .navigationTitle(title(viewStore: viewStore))
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

  private func title(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> String {
    switch viewStore.type {
    case .new:
      String(localized: "New task", bundle: .module)
    case .edit:
      String(localized: "Edit task", bundle: .module)
    }
  }

  private func content(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    VStack(spacing: .zero) {
      formView(viewStore: viewStore)
        .padding(.bottom, 15.0)
      bottomView(viewStore: viewStore)
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
  }

  private func formView(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    ScrollView {
      VStack(spacing: 15.0) {
        isDoneToggleViewIfEdit(viewStore: viewStore)
        imageField(viewStore: viewStore)
        nameTextField(viewStore: viewStore)
        durationFormView(viewStore: viewStore)
        overviewTextField(viewStore: viewStore)
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func isDoneToggleViewIfEdit(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    if case .edit = viewStore.type {
      Toggle(
        isOn: Binding(
          get: { viewStore.dayActivityTask.isDone },
          set: { value in viewStore.send(.view(.isDoneToggleChanged(value))) }
        )
      ) {
        Text("Completed", bundle: .module)
          .formTitleTextStyle
      }
      .toggleStyle(CheckToggleStyle())
      .formBackgroundModifier()
    }
  }

  private func imageField(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
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
          data: viewStore.dayActivityTask.icon?.data,
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

  private func nameTextField(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    FormTextField(
      title: String(localized: "Name", bundle: .module),
      placeholder: String(localized: "Enter name", bundle: .module),
      value: viewStore.$dayActivityTask.name
    )
  }

  private func durationFormView(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    HStack(spacing: 10.0) {
      Text("Set duration", bundle: .module)
        .formTitleTextStyle
      Spacer()
      durationView(viewStore: viewStore)
    }
    .formBackgroundModifier()
  }

  private func durationView(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    DurationPickerView(
      selectedHours: Binding(
        get: { viewStore.dayActivityTask.hours },
        set: { viewStore.$dayActivityTask.wrappedValue.setDurationHours($0) }
      ),
      selectedMinutes: Binding(
        get: { viewStore.dayActivityTask.minutes },
        set: { viewStore.$dayActivityTask.wrappedValue.setDurationMinutes($0) }
      )
    )
  }

  private func overviewTextField(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    FormTextField(
      title: String(localized: "Overview", bundle: .module),
      placeholder: String(localized: "Enter overview", bundle: .module),
      value: Binding(
        get: { viewStore.dayActivityTask.overview ?? "" },
        set: { viewStore.$dayActivityTask.wrappedValue.overview = $0 }
      )
    )
  }

  @ViewBuilder
  private func bottomView(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    VStack(spacing: 10.0) {
      saveButton(viewStore: viewStore)
      deleteButton(viewStore: viewStore)
    }
  }

  private func saveButton(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.saveButtonTapped)) },
      label: { Text("Save", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private func deleteButton(viewStore: ViewStoreOf<DayActivityTaskFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.deleteButtonTapped)) },
      label: { Text("Delete", bundle: .module) }
    )
    .buttonStyle(DestructiveButtonStyle())
  }
}
