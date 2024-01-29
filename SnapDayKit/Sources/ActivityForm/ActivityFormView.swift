import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import TagForm
import EmojiPicker
import PhotosUI

@MainActor
public struct ActivityFormView: View {

  // MARK: - Properties

  private let store: StoreOf<ActivityFormFeature>
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
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore: viewStore)
        .navigationTitle(title(type: viewStore.type))
    }
    .sheet(
      store: store.scope(
        state: \.$addTag,
        action: { .addTag($0) }
      ),
      content: { store in
        NavigationStack {
          TagFormView(store: store)
            .navigationTitle(String(localized: "Add Tag", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
    )
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

  private func content(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    VStack(spacing: .zero) {
      formView(viewStore: viewStore)
        .padding(.bottom, 15.0)
      bottomView(viewStore: viewStore)
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
    .onAppear {
      viewStore.send(.view(.appeared))
    }
    .bind(viewStore.$focus, to: $focus)
  }

  private func formView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    ScrollView {
      VStack(spacing: 15.0) {
        imageField(viewStore: viewStore)
        nameTextField(viewStore: viewStore)
        tagsView(viewStore: viewStore)
        recurrencyView(viewStore: viewStore)
        durationView(viewStore: viewStore)
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  private func imageField(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
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
          data: viewStore.activity.image,
          size: 30.0,
          cornerRadius: 5.0,
          tintColor: Colors.lavenderBliss.swiftUIColor
        )
        Text("Change icon", bundle: .module)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
          .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
        Spacer()
      }
    }
    .formBackgroundModifier
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

  private func nameTextField(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    FormTextField(
      title: String(localized: "Name", bundle: .module),
      placeholder: String(localized: "Enter name", bundle: .module),
      value: viewStore.$activity.name
    )
    .focused($focus, equals: .name)
  }

  private func tagsView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    FormTagField(
      title: String(localized: "Tags", bundle: .module),
      placeholder: String(localized: "Enter tag", bundle: .module),
      existingTagsTitle: String(localized: "Existing tags", bundle: .module),
      tags: viewStore.activity.tags,
      existingTags: viewStore.existingTags,
      newTag: viewStore.$newTag,
      onSubmit: {
        viewStore.send(.view(.submitTagTapped))
      },
      existingTagTapped: { tag in
        viewStore.send(.view(.tagTapped(tag)))
      }
    )
    .focused($focus, equals: .tag)
  }

  private func recurrencyView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    ScrollViewReader { reader in
      VStack(spacing: 10.0) {
        toggleView(viewStore: viewStore)
        frequencyOptionsIfNeeded(viewStore: viewStore, reader: reader)
        weekdaysViewIfNeeded(viewStore: viewStore, reader: reader)
        monthlyScheduleViewIfNeeded(viewStore: viewStore, reader: reader)
        monthGridIfNeeded(viewStore: viewStore, reader: reader)
        monthlyWeekdaysViewIfNeeded(viewStore: viewStore, reader: reader)
      }
      .formBackgroundModifier
      .id("RecurrencyView")
    }
  }

  @ViewBuilder
  private func toggleView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    Toggle(
      isOn: Binding(
        get: { viewStore.activity.isRepeatable },
        set: { value in viewStore.$activity.wrappedValue.setIsRepeatable(value) }
      )
    ) {
      Text("Repeatable", bundle: .module)
        .formTitleTextStyle
    }
    .toggleStyle(CheckToggleStyle())
  }

  @ViewBuilder
  private func frequencyOptionsIfNeeded(viewStore: ViewStoreOf<ActivityFormFeature>, reader: ScrollViewProxy) -> some View {
    if viewStore.showFrequencyOptions {
      OptionsView(
        options: viewStore.options,
        selected: viewStore.$activity.frequency,
        axis: .horizontal(.center)
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func weekdaysViewIfNeeded(viewStore: ViewStoreOf<ActivityFormFeature>, reader: ScrollViewProxy) -> some View {
    if viewStore.showWeekdaysView {
      WeekdaysView(
        selectedWeekdays:  Binding(
          get: { viewStore.activity.weekdays },
          set: { value in viewStore.$activity.wrappedValue.setWeekdays(value) }
        )
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthlyScheduleViewIfNeeded(viewStore: ViewStoreOf<ActivityFormFeature>, reader: ScrollViewProxy) -> some View {
    if viewStore.showMonthlyView {
      OptionsView(
        options: MonthlySchedule.allCases,
        selected: Binding(
          get: { viewStore.activity.monthlySchedule },
          set: { value in viewStore.$activity.wrappedValue.setMonthlySchedule(value) }
        ),
        axis: .horizontal(.center)
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthGridIfNeeded(viewStore: ViewStoreOf<ActivityFormFeature>, reader: ScrollViewProxy) -> some View {
    if viewStore.showMonthDays {
      MonthGrid(
        selectedDays: Binding(
          get: { viewStore.activity.mounthDays },
          set: { value in viewStore.$activity.wrappedValue.setMounthDays(value) }
        )
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func monthlyWeekdaysViewIfNeeded(viewStore: ViewStoreOf<ActivityFormFeature>, reader: ScrollViewProxy) -> some View {
    if viewStore.showMonthWeekdays {
      MonthlyWeekdaysView(
        weekdayOrdinal: Binding(
          get: { viewStore.activity.weekdayOrdinal },
          set: { value in viewStore.$activity.wrappedValue.setWeekdayOrdinal(value) }
        )
      )
      .scrollOnAppear("RecurrencyView", anchor: .bottom, reader: reader)
    }
  }

  @ViewBuilder
  private func bottomView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    if viewStore.showAddTagButton {
      addTagButton(viewStore: viewStore)
    } else {
      saveButton(viewStore: viewStore)
    }
  }

  private func durationView(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    ScrollViewReader { reader in
      VStack(alignment: .leading, spacing: 10.0) {
        Toggle(
          isOn: Binding(
            get: { viewStore.activity.isDefaultDuration },
            set: { viewStore.$activity.wrappedValue.setDefaultDuration($0) }
          )
        ) {
          Text("Default duration", bundle: .module)
            .formTitleTextStyle
        }
        .toggleStyle(CheckToggleStyle())
        if viewStore.activity.isDefaultDuration {
          DurationPickerView(
            selectedHours: Binding(
              get: { viewStore.activity.hours },
              set: { viewStore.$activity.wrappedValue.setDurationHours($0) }
            ),
            selectedMinutes: Binding(
              get: { viewStore.activity.minutes },
              set: { viewStore.$activity.wrappedValue.setDurationMinutes($0) }
            )
          )
          .scrollOnAppear("DurationView", anchor: .bottom, reader: reader)
        }
      }
      .formBackgroundModifier
      .id("DurationView")
    }
  }

  private func addTagButton(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.addTagButtonTapped)) },
      label: { Text("Add tag", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private func saveButton(viewStore: ViewStoreOf<ActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.saveButtonTapped)) },
      label: { Text("Save", bundle: .module) }
    )
    .disabled(viewStore.isSaveButtonDisabled)
    .buttonStyle(PrimaryButtonStyle(disabled: viewStore.isSaveButtonDisabled))
  }
}
