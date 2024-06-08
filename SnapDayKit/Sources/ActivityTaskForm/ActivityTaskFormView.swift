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

  @Perception.Bindable private var store: StoreOf<ActivityTaskFormFeature>
  @FocusState private var focus: ActivityTaskFormFeature.State.Field?
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )
  private var title: String {
    switch store.type {
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
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        formView
          .padding(.bottom, 15.0)
        saveButton
          .padding(.bottom, 15.0)
          .padding(.horizontal, 15.0)
      }
      .activityBackground
      .bind($store.focus, to: $focus)
    }
  }

  private var formView: some View {
    ScrollView {
      VStack(spacing: 15.0) {
        imageField
        nameTextField
        durationView
        reminderFormView
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
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
            data: store.activityTask.icon?.data,
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
        value: $store.activityTask.name
      )
      .focused($focus, equals: .name)
    }
  }

  private var durationView: some View {
    ScrollViewReader { reader in
      WithPerceptionTracking {
        VStack(alignment: .leading, spacing: 10.0) {
          Toggle(
            isOn: Binding(
              get: {
                store.activityTask.isDefaultDuration
              },
              set: {
                $store.activityTask.wrappedValue.setDefaultDuration($0)
              }
            )
          ) {
            Text(String(localized: "Default duration", bundle: .module))
              .formTitleTextStyle
          }
          .toggleStyle(CheckToggleStyle())
          if store.activityTask.isDefaultDuration {
            DurationPickerView(
              selectedHours: Binding(
                get: {
                  store.activityTask.hours
                },
                set: {
                  $store.activityTask.wrappedValue.setDurationHours($0)
                }
              ),
              selectedMinutes: Binding(
                get: {
                  store.activityTask.minutes
                },
                set: {
                  $store.activityTask.wrappedValue.setDurationMinutes($0)
                }
              )
            )
            .scrollOnAppear("DurationView", anchor: .bottom, reader: reader)
          }
        }
        .formBackgroundModifier()
        .id("DurationView")
      }
    }
  }

  private var reminderFormView: some View {
    WithPerceptionTracking {
      ReminderFormView(
        title: String(localized: "Default Reminder", bundle: .module),
        availableDateHours: store.dateHoursAndMinutes,
        toggleBinding: Binding(
          get: {
            store.activityTask.defaultReminderDate != nil
          },
          set: { value in
            store.send(.view(.remindToggeled(value)))
          }
        ),
        dateBinding: $store.activityTask.defaultReminderDate
      )
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
      .disabled(store.isSaveButtonDisabled)
      .buttonStyle(PrimaryButtonStyle(disabled: store.isSaveButtonDisabled))
    }
  }
}
