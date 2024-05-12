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

  @Perception.Bindable private var store: StoreOf<DayActivityTaskFormFeature>
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )
  
  private var title: String {
    switch store.type {
    case .new:
      String(localized: "New task", bundle: .module)
    case .edit:
      String(localized: "Edit task", bundle: .module)
    }
  }

  // MARK: - Initialization

  public init(store: StoreOf<DayActivityTaskFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .navigationTitle(title)
        .fullScreenCover(item: $store.scope(state: \.showEmojiPicker, action: \.showEmojiPicker)) { store in
          NavigationStack {
            EmojiPickerView(store: store)
          }
        }
    }
  }

  private var content: some View {
    VStack(spacing: .zero) {
      formView
        .padding(.bottom, 15.0)
      bottomView
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
  }

  private var formView: some View {
    ScrollView {
      VStack(spacing: 15.0) {
        isDoneToggleViewIfEdit
        imageField
        nameTextField
        durationFormView
        overviewTextField
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private var isDoneToggleViewIfEdit: some View {
    WithPerceptionTracking {
      if case .edit = store.type {
        Toggle(
          isOn: Binding(
            get: { store.dayActivityTask.isDone },
            set: { value in store.send(.view(.isDoneToggleChanged(value))) }
          )
        ) {
          Text("Completed", bundle: .module)
            .formTitleTextStyle
        }
        .toggleStyle(CheckToggleStyle())
        .formBackgroundModifier()
      }
    }
  }

  private var imageField: some View {
    WithPerceptionTracking {
      Menu {
        Button(
          String(localized: "Select Emoji", bundle: .module),
          action: {
            store.send(.view(.iconTapped))
          }
        )
        Button(
          String(localized: "Pick Photo", bundle: .module),
          action: {
            store.send(.view(.pickPhotoTapped))
          }
        )
        Button(
          String(localized: "Remove", bundle: .module),
          action: {
            store.send(.view(.removeImageTapped))
          }
        )
      } label: {
        HStack(spacing: 10.0) {
          ActivityImageView(
            data: store.dayActivityTask.icon?.data,
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
        isPresented: $store.isPhotoPickerPresented,
        selection: Binding(
          get: {
            store.photoItem?.photosPickerItem
          },
          set: { value in
            store.send(.view(.imageSelected(PhotoItem(photosPickerItem: value))))
          }
        ),
        matching: .images,
        preferredItemEncoding: .current,
        photoLibrary: .shared()
      )
    }
  }

  private var nameTextField: some View {
    WithPerceptionTracking {
      FormTextField(
        title: String(localized: "Name", bundle: .module),
        placeholder: String(localized: "Enter name", bundle: .module),
        value: $store.dayActivityTask.name
      )
    }
  }

  private var durationFormView: some View {
    HStack(spacing: 10.0) {
      Text("Set duration", bundle: .module)
        .formTitleTextStyle
      Spacer()
      durationView
    }
    .formBackgroundModifier()
  }

  private var durationView: some View {
    WithPerceptionTracking {
      DurationPickerView(
        selectedHours: Binding(
          get: {
            store.dayActivityTask.hours
          },
          set: {
            $store.dayActivityTask.wrappedValue.setDurationHours($0)
          }
        ),
        selectedMinutes: Binding(
          get: {
            store.dayActivityTask.minutes
          },
          set: {
            $store.dayActivityTask.wrappedValue.setDurationMinutes($0)
          }
        )
      )
    }
  }

  private var overviewTextField: some View {
    WithPerceptionTracking {
      FormTextField(
        title: String(localized: "Overview", bundle: .module),
        placeholder: String(localized: "Enter overview", bundle: .module),
        value: Binding(
          get: {
            store.dayActivityTask.overview ?? ""
          },
          set: {
            $store.dayActivityTask.wrappedValue.overview = $0
          }
        )
      )
    }
  }

  @ViewBuilder
  private var bottomView: some View {
    VStack(spacing: 10.0) {
      saveButton
      deleteButton
    }
  }

  private var saveButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.saveButtonTapped))
        },
        label: {
          Text("Save", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())
    }
  }

  private var deleteButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.deleteButtonTapped))
        },
        label: {
          Text("Delete", bundle: .module)
        }
      )
      .buttonStyle(DestructiveButtonStyle())
    }
  }
}
