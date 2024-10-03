import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models

public struct OnboardingView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<OnboardingFeature>

  // MARK: - Initialization

  public init(store: StoreOf<OnboardingFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button(
                action: {
                  store.send(.view(.skipButtonPressed))
                },
                label: {
                  Text("Skip", bundle: .module)
                    .foregroundStyle(Color.actionBlue)
                    .font(.system(size: 12.0, weight: .bold))
                }
              )
            }
        }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      ZStack {
        VStack(spacing: 10.0) {
          Spacer()

          Button(store.buttonTitle) {
            store.send(.view(.nextButtonPressed))
          }
          .buttonStyle(PrimaryButtonStyle())

          if store.isSkipButtonShown {
            Button(
              action: {
                store.send(.view(.skipButtonPressed))
              },
              label: {
                Text("Skip", bundle: .module)
              }
            )
            .buttonStyle(CancelButtonStyle())
          }
        }
        .padding(.horizontal, 15.0)
        .padding(.bottom, 15.0)

        TabView(selection: $store.selectedTab) {
          OnboardingWelcomeView()
            .modifier(OnboardingViewModifier(tag: .welcome))
          OnboardingFeatureHighlightView(visibileHighlight: $store.visibileHighlight)
            .modifier(OnboardingViewModifier(tag: .featureHighlight))
          OnboardingCloudView()
            .modifier(OnboardingViewModifier(tag: .icloud))
          OnboardingNotificationView()
            .modifier(OnboardingViewModifier(tag: .notification))
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        // PrimaryButtonStyle height + bottom padding + CancelButtonStyle is shown
        .offset(y: -55.0 - (store.isSkipButtonShown ? 40 : .zero))
        .animation(.easeInOut, value: store.selectedTab)
      }
      .activityBackground
    }
  }
}
