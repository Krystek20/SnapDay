import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models

@MainActor
public struct MarkerFormView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<MarkerFormFeature>

  // MARK: - Initialization

  public init(store: StoreOf<MarkerFormFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .navigationTitle(store.title)
        .navigationBarTitleDisplayMode(.large)
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        formView
        Spacer(minLength: 15.0)
        bottomView
          .padding(.bottom, 15.0)
      }
      .padding(.horizontal, 15.0)
      .padding(.top, 25.0)
      .activityBackground
    }
  }

  private var formView: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 15.0) {
        FormTextField(
          title: String(localized: "Name", bundle: .module),
          value: $store.name
        )
        colorsSection
      }
      .maxWidth()
    }
  }

  @ViewBuilder
  private var colorsSection: some View {
    WithPerceptionTracking {
      FormColorField(
        title: String(localized: "Color", bundle: .module),
        color: Binding(
          get: {
            store.color.color
          },
          set: { value in
            $store.color.wrappedValue = value.rgbColor
          }
        )
      )
    }
  }

  private var bottomView: some View {
    WithPerceptionTracking {
      VStack(spacing: 10.0) {
        Button(String(localized: "Save", bundle: .module)) {
          store.send(.view(.saveButtonTapped))
        }
        .disabled(store.name.isEmpty)
        .buttonStyle(PrimaryButtonStyle(disabled: store.name.isEmpty))
      }
    }
  }
}
