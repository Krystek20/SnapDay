import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import MarkerForm
import EmojiPicker
import PhotosUI
import ActivityTaskForm

@MainActor
public struct ActivityFormView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ActivityFormFeature>
  @FocusState private var focus: ActivityFormFeature.State.Field?
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )
  private func title(type: ActivityFormFeature.ActivityFormType) -> String {
    switch type {
    case .new:
      String(localized: "Add Activity", bundle: .module)
    case .edit:
      String(localized: "Edit Activity", bundle: .module)
    }
  }

  // MARK: - Initialization

  public init(store: StoreOf<ActivityFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    content
      .navigationTitle(title(type: store.type))
      .sheet(item: $store.scope(state: \.markerForm, action: \.markerForm)) { store in
        NavigationStack {
          MarkerFormView(store: store)
            .navigationTitle(String(localized: "Add Tag", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
      .sheet(item: $store.scope(state: \.activityTaskForm, action: \.activityTaskForm)) { store in
        NavigationStack {
          ActivityTaskFormView(store: store)
            .navigationTitle(String(localized: "Add Task", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
      .fullScreenCover(item: $store.scope(state: \.emojiPicker, action: \.emojiPicker)) { store in
        NavigationStack {
          EmojiPickerView(store: store)
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
    .onAppear {
      store.send(.view(.appeared))
    }
    .bind($store.focus, to: $focus)
  }

  private var formView: some View {
    ScrollView {
      VStack(spacing: 15.0) {
        imageField
        nameTextField
        tagsView
        recurrencyViewIfNeeded
        durationView
        tasksView
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  private var imageField: some View {
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
          data: store.activity.icon?.data,
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

  private var nameTextField: some View {
    FormTextField(
      title: String(localized: "Name", bundle: .module),
      placeholder: String(localized: "Enter name", bundle: .module),
      value: $store.activity.name
    )
    .focused($focus, equals: .name)
  }

  private var tagsView: some View {
    FormMarkerField(
      title: String(localized: "Tags", bundle: .module),
      placeholder: String(localized: "Enter tag", bundle: .module),
      existingMarkersTitle: String(localized: "Existing tags", bundle: .module),
      markers: store.activity.tags,
      existingMarkers: store.existingTags,
      newMarker: $store.newTag,
      onSubmit: {
        store.send(.view(.submitTagTapped))
      },
      addedMarkerTapped: { marker in
        store.send(.view(.addedTagTapped(marker)))
      },
      existingMarkerTapped: { marker in
        store.send(.view(.existingTagTapped(marker)))
      },
      removeMarker: { marker in
        store.send(.view(.removeTagTapped(marker)))
      }
    )
    .focused($focus, equals: .tag)
  }

  @ViewBuilder
  private var recurrencyViewIfNeeded: some View {
    if store.activity.isVisible {
      ScrollViewReader { reader in
        VStack(spacing: 10.0) {
          toggleView
          frequencyOptionsIfNeeded(reader: reader)
          weekdaysViewIfNeeded(reader: reader)
          monthlyScheduleViewIfNeeded(reader: reader)
          monthGridIfNeeded(reader: reader)
          monthlyWeekdaysViewIfNeeded(reader: reader)
        }
        .formBackgroundModifier()
        .id("RecurrencyView")
      }
    }
  }

  @ViewBuilder
  private var toggleView: some View {
    Toggle(
      isOn: Binding(
        get: { store.activity.isRepeatable },
        set: { value in $store.activity.wrappedValue.setIsRepeatable(value) }
      )
    ) {
      Text("Repeatable", bundle: .module)
        .formTitleTextStyle
    }
    .toggleStyle(CheckToggleStyle())
  }

  @ViewBuilder
  private func frequencyOptionsIfNeeded(reader: ScrollViewProxy) -> some View {
    if store.showFrequencyOptions {
      OptionsView(
        options: store.options,
        selected: $store.activity.frequency,
        axis: .horizontal(.center)
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func weekdaysViewIfNeeded(reader: ScrollViewProxy) -> some View {
    if store.showWeekdaysView {
      WeekdaysView(
        selectedWeekdays:  Binding(
          get: { store.activity.weekdays },
          set: { value in $store.activity.wrappedValue.setWeekdays(value) }
        ),
        weekdays: store.weekdays
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthlyScheduleViewIfNeeded(reader: ScrollViewProxy) -> some View {
    if store.showMonthlyView {
      OptionsView(
        options: MonthlySchedule.allCases,
        selected: Binding(
          get: { store.activity.monthlySchedule },
          set: { value in $store.activity.wrappedValue.setMonthlySchedule(value) }
        ),
        axis: .horizontal(.center)
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthGridIfNeeded(reader: ScrollViewProxy) -> some View {
    if store.showMonthDays {
      MonthGrid(
        selectedDays: Binding(
          get: { store.activity.mounthDays },
          set: { value in $store.activity.wrappedValue.setMounthDays(value) }
        )
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthlyWeekdaysViewIfNeeded(reader: ScrollViewProxy) -> some View {
    if store.showMonthWeekdays {
      MonthlyWeekdaysView(
        weekdayOrdinal: Binding(
          get: { store.activity.weekdayOrdinal },
          set: { value in $store.activity.wrappedValue.setWeekdayOrdinal(value) }
        ),
        weekdays: store.weekdays
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private var bottomView: some View {
    if store.showAddTagButton {
      addTagButton
    } else {
      saveButton
    }
  }

  private var durationView: some View {
    ScrollViewReader { reader in
      VStack(alignment: .leading, spacing: 10.0) {
        Toggle(
          isOn: Binding(
            get: { store.activity.isDefaultDuration },
            set: { $store.activity.wrappedValue.setDefaultDuration($0) }
          )
        ) {
          let durationText = store.activity.isVisible
          ? String(localized: "Default duration", bundle: .module)
          : String(localized: "Duration", bundle: .module)
          Text(durationText)
            .formTitleTextStyle
        }
        .toggleStyle(CheckToggleStyle())
        if store.activity.isDefaultDuration {
          DurationPickerView(
            selectedHours: Binding(
              get: { store.activity.hours },
              set: { $store.activity.wrappedValue.setDurationHours($0) }
            ),
            selectedMinutes: Binding(
              get: { store.activity.minutes },
              set: { $store.activity.wrappedValue.setDurationMinutes($0) }
            )
          )
          .scrollOnAppear("DurationView", anchor: .bottom, reader: reader)
        }
      }
      .formBackgroundModifier()
      .id("DurationView")
    }
  }

  private var tasksView: some View {
    SectionView(
      name: String(localized: "Tasks", bundle: .module),
      rightContent: { },
      content: {
        taskContentView
          .formBackgroundModifier()
      }
    )
  }

  @ViewBuilder
  private var taskContentView: some View {
    LazyVStack(spacing: 10.0) {
      ForEach(store.activity.tasks) { task in
        ActivityTaskView(
          activityTask: task,
          editTapped: { task in
            store.send(.view(.editButtonTapped(task)))
          },
          removeTapped: { task in
            store.send(.view(.removeButtonTapped(task)))
          }
        )
        Divider()
      }
      addTaskButton
    }
  }

  private var addTaskButton: some View {
    Button(
      action: { store.send(.view(.addTaskButtonTapped)) },
      label: {
        Text("Add task", bundle: .module)
          .foregroundStyle(Color.actionBlue)
          .font(.system(size: 12.0, weight: .bold))
      }
    )
    .maxFrame()
  }

  private var addTagButton: some View {
    Button(
      action: { store.send(.view(.addTagButtonTapped)) },
      label: { Text("Add tag", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private var saveButton: some View {
    Button(
      action: { store.send(.view(.saveButtonTapped)) },
      label: { Text("Save", bundle: .module) }
    )
    .disabled(store.isSaveButtonDisabled)
    .buttonStyle(PrimaryButtonStyle(disabled: store.isSaveButtonDisabled))
  }
}
