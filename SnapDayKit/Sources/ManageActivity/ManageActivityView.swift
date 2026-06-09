import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct ManageActivityView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<ManageActivityFeature>
  @FocusState private var focus: ManageActivityFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<ManageActivityFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .center, spacing: 16.0) {
      VStack(spacing: 8.0) {
        FormTextField(
          placeholder: String(localized: "Type your request...", bundle: .module),
          value: $store.transcribedText,
          lineLimit: 3
        )
        .fixedSize(horizontal: false, vertical: true)
        .focused($focus, equals: .request)
        .disabled(store.isTextFieldDisabled)

        if !store.listItemsSections.isEmpty {
          ScrollView{
            VStack(spacing: 15.0) {
              ForEach(store.listItemsSections) { section in
                VStack(spacing: .zero) {
                  ForEach(section.listItems) { decisionListItem in
                    ListItemView(item: .constant(decisionListItem.listItem))
                      .padding(.leading, CGFloat(decisionListItem.indent) * 15.0)
                      .opacity(decisionListItem.disabled ? 0.3 : 1.0)
                      .disabled(decisionListItem.disabled)
                      .onListItemAction { actionId, item in
                        store.send(.view(.listItemTapped(actionId, item)))
                      }
                  }
                }
                .formBackgroundModifier(padding: EdgeInsets(.zero))
              }
            }
          }
        } else if store.showProcessingState {
          AIProcessingStateView()
        } else {
          Text("e.g. add gym on Monday evening, set reminder 10 minutes before...", bundle: .module)
            .lineLimit(2)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.secondaryText)
            .multilineTextAlignment(.leading)
            .maxWidth()
            .padding(.horizontal, 10.0)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      if !store.showProcessingState {
        HStack {
          Rectangle()
            .frame(height: 1)
            .foregroundColor(.border)
          Text("or", bundle: .module)
            .font(.system(size: 14.0, weight: .regular))
            .foregroundStyle(Color.primaryText)
          Rectangle()
            .frame(height: 1)
            .foregroundColor(.border)
        }

        VStack(spacing: 8.0) {
          Button {
            store.send(.view(.micButtonTapped))
          } label: {
            Circle()
              .fill(Color.actionBlue)
              .frame(width: 54.0, height: 54.0)
              .overlay(
                buttonIcon
                  .foregroundStyle(.white)
                  .font(.system(size: 22, weight: .semibold))
              )
          }

          Text(buttonTitle)
            .font(.system(size: 14.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)
        }
      }

      Spacer()

      switch store.bottomSection {
      case .cancelButton:
        cancelButton
      case .confirmButton(let isDisabled):
        confirmButton(isDisabled: isDisabled)
      case .acceptDiscardButtons:
        acceptDiscardButtons
      case .done:
        doneButton
      }
    }
    .padding(.horizontal, 15)
    .padding(.bottom, 15)
    .maxFrame()
    .backgroundSoft
    .bind($store.focus, to: $focus)
    .navigationTitle(String(localized: "What Should I Do?", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color.backgroundSoft, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button(String(localized: "Cancel", bundle: .module)) {
          store.send(.view(.cancelButtonTapped))
        }
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
      }
    }
  }

  private var buttonTitle: String {
    store.isListening
    ? String(localized: "Listening...", bundle: .module)
    : String(localized: "Tap to speak", bundle: .module)
  }

  @ViewBuilder
  private var buttonIcon: some View {
    Image(systemName: store.isListening ? "waveform.and.mic" : "mic.fill")
      .symbolEffect(.pulse.byLayer, isActive: store.isListening)
  }

  private func confirmButton(isDisabled: Bool) -> some View {
    Button(
      action: {
        store.send(.view(.confirmButtonTapped))
      },
      label: {
        Text("Confirm", bundle: .module)
      }
    )
    .disabled(isDisabled)
    .buttonStyle(PrimaryButtonStyle())
  }

  private var cancelButton: some View {
    Button(
      action: {
        store.send(.view(.cancelButtonTapped))
      },
      label: {
        Text("Cancel", bundle: .module)
      }
    )
    .buttonStyle(PrimaryButtonStyle())
  }

  private var acceptDiscardButtons: some View {
    VStack(spacing: 8.0) {
      Button(
        action: {
          store.send(.view(.acceptButtonTapped))
        },
        label: {
          Text("Accept all", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())

      Button(
        action: {
          store.send(.view(.discardButtonTapped))
        },
        label: {
          Text("Discard all", bundle: .module)
        }
      )
      .buttonStyle(DestructiveButtonStyle())
    }
  }

  private var doneButton: some View {
    Button(
      action: {
        store.send(.view(.doneButtonTapped))
      },
      label: {
        Text("Done", bundle: .module)
      }
    )
    .buttonStyle(PrimaryButtonStyle())
  }
}

struct AIProcessingStateView: View {
  var message: String = "Understanding your request…"

  var body: some View {
    HStack(spacing: 12.0) {
      ProgressView()
        .progressViewStyle(.circular)

      VStack(alignment: .leading, spacing: 2) {
        Text(message)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color.primaryText)

        Text("This won’t take long")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(Color.secondaryText)
      }

      Spacer(minLength: .zero)
    }
    .formBackgroundModifier()
    .transition(.opacity.combined(with: .scale))
    .animation(.easeInOut(duration: 0.25), value: message)
  }
}
