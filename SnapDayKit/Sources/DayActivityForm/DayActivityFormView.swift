import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models

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
  }

  private func content(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    VStack(spacing: 15.0) {
      formView(viewStore: viewStore)
      overviewTextField(viewStore: viewStore)
      Spacer()
      bottomView(viewStore: viewStore)
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
  }

  private func formView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    HStack(spacing: 10.0) {
      Text("Set duration", bundle: .module)
        .formTitleTextStyle
      Spacer()
      durationView(viewStore: viewStore)
    }
    .maxWidth()
    .formBackgroundModifier()
    .padding(padding)
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
    .padding(.horizontal, 15.0)
  }

  private func bottomView(viewStore: ViewStoreOf<DayActivityFormFeature>) -> some View {
    VStack(spacing: 10.0) {
      saveButton(viewStore: viewStore)
      deleteButton(viewStore: viewStore)
    }
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
