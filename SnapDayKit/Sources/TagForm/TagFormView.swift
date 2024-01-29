import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models

@MainActor
public struct TagFormView: View {

  // MARK: - Properties

  private let store: StoreOf<TagFormFeature>

  // MARK: - Initialization

  public init(store: StoreOf<TagFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: .zero) {
        formView(viewStore: viewStore)
        Spacer(minLength: 15.0)
        bottomView(viewStore: viewStore)
          .padding(.bottom, 15.0)
      }
      .padding(.horizontal, 15.0)
      .padding(.top, 25.0)
      .activityBackground
    }
  }

  private func formView(viewStore: ViewStoreOf<TagFormFeature>) -> some View {
    VStack(alignment: .leading, spacing: 15.0) {
      FormTextField(
        title: String(localized: "Name", bundle: .module),
        value: viewStore.$tag.name
      )
      colorsSection(viewStore: viewStore)
    }
    .maxWidth()
  }

  @ViewBuilder
  private func colorsSection(viewStore: ViewStoreOf<TagFormFeature>) -> some View {
    let binding = Binding(
      get: { viewStore.tag.rgbColor.color },
      set: { value in viewStore.$tag.rgbColor.wrappedValue = value.rgbColor }
    )
    FormColorField(title: String(localized: "Color", bundle: .module), color: binding)
  }

  private func bottomView(viewStore: ViewStoreOf<TagFormFeature>) -> some View {
    VStack(spacing: 10.0) {
      Button(String(localized: "Save", bundle: .module)) {
        viewStore.send(.view(.saveButtonTapped))
      }
      .disabled(viewStore.tag.name.isEmpty)
      .buttonStyle(PrimaryButtonStyle(disabled: viewStore.tag.name.isEmpty))
    }
  }
}
