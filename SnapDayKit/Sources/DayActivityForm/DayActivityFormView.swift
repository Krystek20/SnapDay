import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import MarkerForm

@MainActor
public struct DayActivityFormView: View {

  // MARK: - Properties

  private let store: StoreOf<DayActivityFormFeature>
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
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore: viewStore)
        .navigationTitle(String(localized: "Edit day activity", bundle: .module))
    }
    .sheet(
      store: store.scope(
        state: \.$addMarker,
        action: { .addMarker($0) }
      ),
      content: { store in
        NavigationStack {
          MarkerFormView(store: store)
            .navigationTitle(String(localized: "Add Tag", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
    )
  }

  private func content(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
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
  }

  private func formView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    ScrollView {
      VStack(spacing: 15.0) {
        isDoneToggleView(viewStore: viewStore)
        durationFormView(viewStore: viewStore)
        overviewTextField(viewStore: viewStore)
        tagsView(viewStore: viewStore)
        labelsView(viewStore: viewStore)
      }
      .padding(padding)
      .maxWidth()
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func isDoneToggleView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    Toggle(
      isOn: Binding(
        get: { viewStore.dayActivity.isDone },
        set: { value in viewStore.send(.view(.isDoneToggleChanged(value))) }
      )
    ) {
      Text("Completed", bundle: .module)
        .formTitleTextStyle
    }
    .toggleStyle(CheckToggleStyle())
    .formBackgroundModifier()
  }

  private func durationFormView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    HStack(spacing: 10.0) {
      Text("Set duration", bundle: .module)
        .formTitleTextStyle
      Spacer()
      durationView(viewStore: viewStore)
    }
    .formBackgroundModifier()
  }

  private func durationView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    DurationPickerView(
      selectedHours: Binding(
        get: { viewStore.dayActivity.hours },
        set: { viewStore.$dayActivity.wrappedValue.setDurationHours($0) }
      ),
      selectedMinutes: Binding(
        get: { viewStore.dayActivity.minutes },
        set: { viewStore.$dayActivity.wrappedValue.setDurationMinutes($0) }
      )
    )
  }

  @State private var name: String = ""

  private func overviewTextField(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    FormTextField(
      title: String(localized: "Overview", bundle: .module),
      placeholder: String(localized: "Enter overview", bundle: .module),
      value: Binding(
        get: { viewStore.dayActivity.overview ?? "" },
        set: { viewStore.$dayActivity.wrappedValue.overview = $0 }
      )
    )
  }

  private func tagsView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    FormMarkerField(
      title: String(localized: "Tags", bundle: .module),
      placeholder: String(localized: "Enter tag", bundle: .module),
      existingMarkersTitle: String(localized: "Existing tags", bundle: .module),
      markers: viewStore.dayActivity.tags,
      existingMarkers: viewStore.existingTags,
      newMarker: viewStore.$newTag,
      onSubmit: {
        viewStore.send(.view(.submitTagTapped))
      },
      addedMarkerTapped: { marker in
        viewStore.send(.view(.addedTagTapped(marker)))
      },
      existingMarkerTapped: { marker in
        viewStore.send(.view(.existingTagTapped(marker)))
      },
      removeMarker: { marker in
        viewStore.send(.view(.removeTagTapped(marker)))
      }
    )
  }

  private func labelsView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    FormMarkerField(
      title: String(localized: "Labels", bundle: .module),
      placeholder: String(localized: "Enter label", bundle: .module),
      existingMarkersTitle: String(localized: "Existing labels", bundle: .module),
      markers: viewStore.dayActivity.labels,
      existingMarkers: viewStore.existingLabels,
      newMarker: viewStore.$newLabel,
      onSubmit: {
        viewStore.send(.view(.submitLabelTapped))
      },
      addedMarkerTapped: { label in
        viewStore.send(.view(.addedLabelTapped(label)))
      },
      existingMarkerTapped: { label in
        viewStore.send(.view(.existingLabelTapped(label)))
      },
      removeMarker: { label in
        viewStore.send(.view(.removeLabelTapped(label)))
      }
    )
  }

  @ViewBuilder
  private func bottomView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    if viewStore.showAddTagButton {
      addTagButton(viewStore: viewStore)
    } else if viewStore.showAddLabelButton {
      addLabelButton(viewStore: viewStore)
    } else {
      VStack(spacing: 10.0) {
        saveButton(viewStore: viewStore)
        deleteButton(viewStore: viewStore)
      }
    }
  }

  private func addTagButton(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.addTagButtonTapped)) },
      label: { Text("Add tag", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private func addLabelButton(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.addLabelButtonTapped)) },
      label: { Text("Add Label", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private func saveButton(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.saveButtonTapped)) },
      label: { Text("Save", bundle: .module) }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private func deleteButton(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.deleteButtonTapped)) },
      label: { Text("Delete", bundle: .module) }
    )
    .buttonStyle(DestructiveButtonStyle())
  }
}
