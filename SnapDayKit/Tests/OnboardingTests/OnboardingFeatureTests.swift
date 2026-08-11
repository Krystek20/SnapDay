import ComposableArchitecture
import Testing
@testable import Onboarding

@MainActor
struct OnboardingFeatureTests {

  @Test
  func selectingGoalEnablesProgression() async {
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }

    await store.send(.view(.goalTapped(.moveMore))) {
      $0.selectedGoal = .moveMore
    }
  }

  @Test
  func continueWithoutSelectionDoesNothing() async {
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped))
  }

  @Test
  func continueDelegatesSelectedGoal() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .healthyHabit)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped))
    await store.receive(.delegate(.goalSelected(.healthyHabit)))
  }

  @Test
  func skipDelegatesWithoutSelectingGoal() async {
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }

    await store.send(.view(.skipButtonTapped))
    await store.receive(.delegate(.skipped))
  }
}
