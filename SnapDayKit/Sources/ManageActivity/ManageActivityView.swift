import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

struct UserDecisionCard: Equatable {
  let title: String
  let subtitle: String?
  let item: ListItem
}

@MainActor
public struct ManageActivityView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ManageActivityFeature>
  @FocusState private var focus: ManageActivityFeature.State.Field?

  // MARK: - Initialization

  public init(store: StoreOf<ManageActivityFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
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

          if let userDecisionCard = store.userDecisionCard {
            VStack(alignment: .leading, spacing: 16) {
              VStack(alignment: .leading, spacing: 4) {
                Text(userDecisionCard.title)
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(Color.primaryText)

                if let subtitle = userDecisionCard.subtitle {
                  Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
                }
              }

              ListItemView(item: .constant(userDecisionCard.item))
                .formBackgroundModifier(padding: EdgeInsets(.zero))
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
              .padding(.horizontal, 8.0)
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
    }
  }

  private var buttonTitle: String {
    store.isListening
    ? String(localized: "Listening...", bundle: .module)
    : String(localized: "Tap to speak", bundle: .module)
  }

  @ViewBuilder
  private var buttonIcon: some View {
    if #available(iOS 17.0, *) {
      Image(systemName: store.isListening ? "waveform.and.mic" : "mic.fill")
        .symbolEffect(.pulse.byLayer, isActive: store.isListening)
    } else {
      Image(systemName: store.isListening ? "waveform.and.mic" : "mic.fill")
    }
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
          Text("Accept", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())

      Button(
        action: {
          store.send(.view(.discardButtonPressed))
        },
        label: {
          Text("Discard", bundle: .module)
        }
      )
      .buttonStyle(DestructiveButtonStyle())
    }
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
