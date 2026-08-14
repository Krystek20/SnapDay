import ComposableArchitecture
import Foundation
import Testing
import Utilities
@testable import Onboarding
@testable import Plans

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
  func continueWithReadingGoalShowsReadingTemplates() async throws {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .readMore)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.path.append(.templateSelection(.init(category: .reading)))
    }

    let pathID = try #require(store.state.path.ids.last)
    await store.send(
      .path(.element(
        id: pathID,
        action: .templateSelection(.view(.useTemplateTapped))
      ))
    )
    await store.receive(
      .path(.element(
        id: pathID,
        action: .templateSelection(
          .delegate(.createPlanRequested(readingRequest))
        )
      ))
    )
    await store.receive(.delegate(.createPlanRequested(readingRequest)))
  }

  @Test
  func continueWithMovementGoalShowsMovementTemplates() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .moveMore)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.path.append(.templateSelection(.init(category: .movement)))
    }
  }

  @Test
  func continueWithHealthyHabitGoalShowsHealthyHabitTemplates() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .healthyHabit)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.path.append(.templateSelection(.init(category: .healthyHabit)))
    }
  }

  @Test
  func continueWithLearningGoalShowsLearningTemplates() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .learnSomething)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.path.append(.templateSelection(.init(category: .learning)))
    }
  }

  @Test
  func createMyOwnRequestsEmptyPlan() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .createMyOwn)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped))
    await store.receive(.delegate(.createPlanRequested(.empty)))
  }

  @Test
  func presentingPlanPushesItOntoOnboardingPath() async {
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    let planState = NewPlanFeature.State(
      onboardingName: "Read",
      startDate: Date(timeIntervalSinceReferenceDate: 800_000_000),
      suggestedActivity: nil,
      scheduledWeekdays: [],
      calendar: calendar
    )
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }

    await store.send(.presentPlan(planState)) {
      $0.newPlan = planState
      $0.path.append(.newPlanStep(.details))
    }
  }

  @Test
  func cancellingPushedPlanReturnsToPreviousOnboardingScreen() async throws {
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    var state = OnboardingFeature.State(selectedGoal: .readMore)
    state.path.append(.templateSelection(.init(category: .reading)))
    state.newPlan = NewPlanFeature.State(
      onboardingName: "Read",
      startDate: Date(timeIntervalSinceReferenceDate: 800_000_000),
      suggestedActivity: nil,
      scheduledWeekdays: [],
      calendar: calendar
    )
    state.path.append(.newPlanStep(.details))
    let store = TestStore(initialState: state) {
      OnboardingFeature()
    }
    let planPathID = try #require(store.state.path.ids.last)

    await store.send(.newPlan(.delegate(.cancelTapped)))
    await store.receive(.path(.popFrom(id: planPathID))) {
      $0.newPlan = nil
      $0.path.removeLast()
    }
    await store.receive(.delegate(.planCreationCancelled))

    #expect(store.state.path.count == 1)
  }

  @Test
  func planStepsUseOnboardingPathAndBackPreservesDraft() async throws {
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    var state = OnboardingFeature.State()
    state.newPlan = NewPlanFeature.State(
      onboardingName: "Reading plan",
      startDate: Date(timeIntervalSinceReferenceDate: 800_000_000),
      suggestedActivity: nil,
      scheduledWeekdays: [],
      calendar: calendar
    )
    state.path.append(.newPlanStep(.details))
    let store = TestStore(initialState: state) {
      OnboardingFeature()
    }

    await store.send(.newPlan(.view(.continueButtonTapped))) {
      $0.newPlan?.step = .weeklySchedule
    }
    await store.receive(.newPlan(.delegate(.stepChanged(.weeklySchedule)))) {
      $0.path.append(.newPlanStep(.weeklySchedule))
    }

    let weeklyScheduleID = try #require(store.state.path.ids.last)
    await store.send(.path(.popFrom(id: weeklyScheduleID))) {
      $0.path.removeLast()
    }
    await store.receive(.newPlan(.view(.navigationPathChanged([])))) {
      $0.newPlan?.step = .details
    }

    #expect(store.state.newPlan?.name == "Reading plan")
    #expect(store.state.path.last == .newPlanStep(.details))
  }

  @Test
  func organizeMyDayCompletesOnboarding() async {
    let store = TestStore(
      initialState: OnboardingFeature.State(selectedGoal: .organizeMyDay)
    ) {
      OnboardingFeature()
    }

    await store.send(.view(.continueButtonTapped))
    await store.receive(.delegate(.completed))
  }

  @Test
  func skipDelegatesWithoutSelectingGoal() async {
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }

    await store.send(.view(.skipButtonTapped))
    await store.receive(.delegate(.skipped))
  }

  private var readingRequest: OnboardingPlanRequest {
    OnboardingPlanRequest(
      name: "Read 15 minutes a day",
      activityTitle: "Read for 15 minutes",
      cadence: .daily
    )
  }
}
