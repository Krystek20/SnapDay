import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import MarkerForm
import EmojiPicker
import PhotosUI

@MainActor
public struct DayActivityFormView: View {

  // MARK: - Properties

  @FocusState private var focus: DayActivityFormFeature.State.Field?
  @Perception.Bindable private var store: StoreOf<DayActivityFormFeature>
  private let padding = EdgeInsets(
    top: 10.0,
    leading: 15.0,
    bottom:  .zero,
    trailing: 15.0
  )

  // MARK: - Initialization

  public init(store: StoreOf<DayActivityFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .navigationTitle(store.title)
        .fullScreenCover(item: $store.scope(state: \.emojiPicker, action: \.emojiPicker)) { store in
          NavigationStack {
            EmojiPickerView(store: store)
          }
        }
        .sheet(item: $store.scope(state: \.addMarker, action: \.addMarker)) { store in
          NavigationStack {
            MarkerFormView(store: store)
          }
          .presentationDetents([.medium])
        }
        .sheet(item: $store.scope(state: \.dayActivityTaskForm, action: \.dayActivityTaskForm)) { store in
          NavigationStack {
            DayActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
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
  }

  private var formView: some View {
    ScrollView {
      VStack(spacing: 15.0) {
        prepareView(for: .completed)
        prepareView(for: .icon)
        prepareView(for: .name)
        prepareView(for: .tags)
        prepareView(for: .frequency)
        prepareView(for: .duration)
        prepareView(for: .dueDate)
        prepareView(for: .reminder)
        prepareView(for: .overview)
        prepareView(for: .labels)
        prepareView(for: .tasks)
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func prepareView(for field: DayActivityField) -> some View {
    WithPerceptionTracking {
      if store.form.fields.contains(field) {
        switch field {
        case .completed:
          completedView
        case .icon:
          iconView
        case .name:
          nameView
        case .tags:
          tagsView
        case .frequency:
          frequencyView
        case .duration:
          durationView
        case .reminder:
          reminderView
        case .dueDate:
          dueDateView
        case .overview:
          overviewView
        case .tasks:
          tasksView
        case .labels:
          labelsView
        }
      }
    }
  }

  private var completedView: some View {
    WithPerceptionTracking {
      Toggle(isOn: $store.form.completed) {
        Text("Completed", bundle: .module)
          .formTitleTextStyle
      }
      .toggleStyle(CheckToggleStyle())
      .formBackgroundModifier()
    }
  }

  private var iconView: some View {
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
            data: store.form.icon?.data,
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

  private var nameView: some View {
    WithPerceptionTracking {
      FormTextField(
        title: String(localized: "Name", bundle: .module),
        placeholder: String(localized: "Enter name", bundle: .module),
        value: $store.form.name
      )
      .focused($focus, equals: .name)
    }
  }

  private var tagsView: some View {
    WithPerceptionTracking {
      FormMarkerField(
        title: String(localized: "Tags", bundle: .module),
        placeholder: String(localized: "Enter tag", bundle: .module),
        existingMarkersTitle: String(localized: "Existing tags", bundle: .module),
        markers: store.form.tags,
        existingMarkers: store.existingTags,
        newMarker: $store.newTag,
        onSubmit: {
          store.send(.view(.tag(.submitTapped)))
        },
        addedMarkerTapped: { marker in
          store.send(.view(.tag(.addedTapped(marker))))
        },
        existingMarkerTapped: { marker in
          store.send(.view(.tag(.existingTapped(marker))))
        },
        removeMarker: { marker in
          store.send(.view(.tag(.removeTapped(marker))))
        }
      )
    }
  }

  // MARK: - Frequency View

  @ViewBuilder
  private var frequencyView: some View {
    WithPerceptionTracking {
      ScrollViewReader { reader in
        WithPerceptionTracking {
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
  }
  
  @ViewBuilder
  private var toggleView: some View {
    WithPerceptionTracking {
      Toggle(
        isOn: Binding(
          get: { store.form.isRepeatable },
          set: { value in $store.form.wrappedValue.setIsRepeatable(value) }
        )
      ) {
        Text("Repeatable", bundle: .module)
          .formTitleTextStyle
      }
      .toggleStyle(CheckToggleStyle())
    }
  }

  @ViewBuilder
  private func frequencyOptionsIfNeeded(reader: ScrollViewProxy) -> some View {
    WithPerceptionTracking {
      if store.showFrequencyOptions {
        OptionsView(
          options: ActivityFrequency.allCases,
          selected: $store.form.frequency,
          axis: .horizontal(.center)
        )
        .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
      }
    }
  }

  @ViewBuilder
  private func weekdaysViewIfNeeded(reader: ScrollViewProxy) -> some View {
    WithPerceptionTracking {
      if store.showWeekdaysView {
        WeekdaysView(
          selectedWeekdays:  Binding(
            get: { store.form.weekdays },
            set: { value in $store.form.wrappedValue.setWeekdays(value) }
          ),
          weekdays: store.weekdays
        )
        .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
      }
    }
  }

  @ViewBuilder
  private func monthlyScheduleViewIfNeeded(reader: ScrollViewProxy) -> some View {
    WithPerceptionTracking {
      if store.showMonthlyView {
        OptionsView(
          options: MonthlySchedule.allCases,
          selected: Binding(
            get: { store.form.monthlySchedule },
            set: { value in $store.form.wrappedValue.setMonthlySchedule(value) }
          ),
          axis: .horizontal(.center)
        )
        .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
      }
    }
  }

  @ViewBuilder
  private func monthGridIfNeeded(reader: ScrollViewProxy) -> some View {
    WithPerceptionTracking {
      if store.showMonthDays {
        MonthGrid(
          selectedDays: Binding(
            get: { store.form.mounthDays },
            set: { value in $store.form.wrappedValue.setMounthDays(value) }
          )
        )
        .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
      }
    }
  }

  @ViewBuilder
  private func monthlyWeekdaysViewIfNeeded(reader: ScrollViewProxy) -> some View {
    WithPerceptionTracking {
      if store.showMonthWeekdays {
        MonthlyWeekdaysView(
          weekdayOrdinal: Binding(
            get: { store.form.weekdayOrdinal },
            set: { value in $store.form.wrappedValue.setWeekdayOrdinal(value) }
          ),
          weekdays: store.weekdays
        )
        .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
      }
    }
  }

  // MARK: - Duration View

  private var durationView: some View {
    HStack(spacing: 10.0) {
      Text("Set duration", bundle: .module)
        .formTitleTextStyle
      Spacer()
      durationPicker
    }
    .formBackgroundModifier()
  }

  private var durationPicker: some View {
    WithPerceptionTracking {
      DurationPickerView(
        selectedHours: Binding(
          get: {
            store.form.hours
          },
          set: {
            $store.form.wrappedValue.setDurationHours($0)
          }
        ),
        selectedMinutes: Binding(
          get: {
            store.form.minutes
          },
          set: {
            $store.form.wrappedValue.setDurationMinutes($0)
          }
        )
      )
    }
  }

  // MARK: - Reminder View

  @ViewBuilder
  private var reminderView: some View {
    WithPerceptionTracking {
      if store.canShowDateForms {
        DateFormView(
          configuration: DateFormView.Configuration(
            title: String(localized: "Reminder", bundle: .module),
            label: String(localized: "Set time", bundle: .module),
            components: [.hourAndMinute]
          ),
          toggleBinding: Binding(
            get: {
              store.form.reminderDate != nil
            },
            set: { value in
              store.send(.view(.remindToggeled(value)))
            }
          ),
          dateBinding: $store.form.reminderDate
        )
      }
    }
  }

  // MARK: - DueDate View

  @ViewBuilder
  private var dueDateView: some View {
    WithPerceptionTracking {
      if store.canShowDateForms {
        DateFormView(
          configuration: DateFormView.Configuration(
            title: String(localized: "Due date", bundle: .module),
            label: String(localized: "Set date", bundle: .module),
            components: [.date],
            range: store.today...
          ),
          toggleBinding: Binding(
            get: {
              store.form.dueDate != nil
            },
            set: { value in
              store.send(.view(.dueTimeToggeled(value)))
            }
          ),
          dateBinding: $store.form.dueDate
        )
      }
    }
  }

  private var overviewView: some View {
    WithPerceptionTracking {
      FormTextField(
        title: String(localized: "Overview", bundle: .module),
        placeholder: String(localized: "Enter overview", bundle: .module),
        value: $store.form.overview
      )
    }
  }

  private var labelsView: some View {
    WithPerceptionTracking {
      FormMarkerField(
        title: String(localized: "Labels", bundle: .module),
        placeholder: String(localized: "Enter label", bundle: .module),
        existingMarkersTitle: String(localized: "Existing labels", bundle: .module),
        markers: store.form.labels,
        existingMarkers: store.existingLabels,
        newMarker: $store.newLabel,
        onSubmit: {
          store.send(.view(.label(.submitTapped)))
        },
        addedMarkerTapped: { label in
          store.send(.view(.label(.addedTapped(label))))
        },
        existingMarkerTapped: { label in
          store.send(.view(.label(.existingTapped(label))))
        },
        removeMarker: { label in
          store.send(.view(.label(.removeTapped(label))))
        }
      )
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
    WithPerceptionTracking {
      VStack(spacing: 10.0) {
        if store.newActivityTask.isFormVisible {
          newActivityTaskForm
          Divider()
        }
        ForEach(store.form.tasks) { task in
          DayActivityTaskRowView(
            dayActivityTask: task,
            selectTapped: { task in
              store.send(.view(.task(.selectButtonTapped(task))))
            },
            editTapped: { task in
              store.send(.view(.task(.editButtonTapped(task))))
            },
            removeTapped: { task in
              store.send(.view(.task(.removeButtonTapped(task))))
            }
          )
          Divider()
        }
        addTaskButton
      }
    }
  }

  @ViewBuilder
  private var newActivityTaskForm: some View {
    WithPerceptionTracking {
      HStack(spacing: 5.0) {
        ActivityImageView(
          data: nil,
          size: 30.0,
          cornerRadius: 15.0
        )
        TextField("", text: $store.newActivityTask.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
          .submitLabel(.done)
          .focused($focus, equals: .newTask)
        Spacer()
        if !store.newActivityTask.name.isEmpty {
          Button(String(localized: "Cancel", bundle: .module), action: {
            store.send(.view(.task(.newActivityActionPerformed(.dayActivityTask(.cancelled)))))
          })
          .font(.system(size: 12.0, weight: .bold))
          .foregroundStyle(Color.actionBlue)
        }
      }
      .onSubmit {
        store.send(.view(.task(.newActivityActionPerformed(.dayActivityTask(.submitted)))))
      }
    }
  }

  private var addTaskButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.task(.addButtonTapped)))
        },
        label: {
          Text("Add task", bundle: .module)
            .foregroundStyle(Color.actionBlue)
            .font(.system(size: 12.0, weight: .bold))
        }
      )
      .maxFrame()
    }
  }

  @ViewBuilder
  private var bottomView: some View {
    WithPerceptionTracking {
      if store.showAddTagButton {
        addTagButton
      } else if store.showAddLabelButton {
        addLabelButton
      } else {
        VStack(spacing: 10.0) {
          saveButton
          deleteButton
        }
      }
    }
  }

  private var addTagButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.tag(.addButtonTapped)))
        },
        label: {
          Text("Add tag", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())
    }
  }

  private var addLabelButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.label(.addButtonTapped)))
        },
        label: {
          Text("Add Label", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())
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
