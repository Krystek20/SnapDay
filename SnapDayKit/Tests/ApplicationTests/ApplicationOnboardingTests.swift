import ComposableArchitecture
#if DEBUG
import DeveloperTools
#endif
import Foundation
import Models
import Repositories
import Testing
import Utilities
@testable import Application
@testable import Onboarding
@testable import Plans

@MainActor
struct ApplicationOnboardingTests {

  @Test
  func organizeMyDayCompletesOnboarding() async throws {
    let userDefaults = try makeUserDefaults()
    let store = makeStore(userDefaults: userDefaults)

    await store.send(.onboarding(.delegate(.completed))) {
      $0.onboarding = OnboardingFeature.State()
      $0.showOnboarding = false
    }

    #expect(userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func createPlanKeepsOnboardingVisibleAndPushesPrefilledFlow() async throws {
    let userDefaults = try makeUserDefaults()
    let store = makeStore(userDefaults: userDefaults)
    store.exhaustivity = .off(showSkippedAssertions: false)
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    let startDate = calendar.startOfDay(
      for: Date(timeIntervalSinceReferenceDate: 800_000_000)
    )
    let request = OnboardingPlanRequest(
      name: "Read 15 minutes a day",
      activityTitle: "Read for 15 minutes",
      cadence: .daily
    )
    let activityID = try #require(
      UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    )

    await store.send(.onboarding(.delegate(.createPlanRequested(request)))) {
      $0.onboardingGeneratedActivityIDs = [activityID]
    }
    await store.receive(
      .onboarding(
        .presentPlan(
          NewPlanFeature.State(
            onboardingName: request.name,
            startDate: startDate,
            suggestedActivity: Activity(
              id: activityID,
              name: "Read for 15 minutes",
              startDate: startDate
            ),
            scheduledWeekdays: Set(PlanWeekday.allCases),
            calendar: calendar
          )
        )
      )
    )

    #expect(store.state.showOnboarding)
    #expect(!userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func cancellingNewPlanReturnsToOnboardingWithoutSaving() async throws {
    let userDefaults = try makeUserDefaults()
    var state = ApplicationFeature.State(userDefaults: userDefaults)
    state.onboarding = OnboardingFeature.State(selectedGoal: .readMore)
    state.onboardingGeneratedActivityIDs = [UUID()]
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.onboarding(.delegate(.planCreationCancelled))) {
      $0.onboardingGeneratedActivityIDs = []
    }

    #expect(store.state.showOnboarding)
    #expect(store.state.onboarding == OnboardingFeature.State(selectedGoal: .readMore))
    #expect(!userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func cancellingNewPlanCancelsInFlightPersistence() async throws {
    let userDefaults = try makeUserDefaults()
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    let startDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))
    )
    let activity = Activity(id: UUID(), name: "Read", startDate: startDate)
    let draft = NewPlanDraft(
      name: "Reading plan",
      duration: .sevenDays,
      startDate: startDate,
      endDate: try #require(calendar.date(byAdding: .day, value: 6, to: startDate)),
      schedule: [ScheduledPlanDay(weekday: .monday, activities: [activity])]
    )
    var state = withDependencies {
      $0.utcCalendar = calendar
      $0.date.now = startDate
      $0.uuid = .incrementing
      $0.deeplinkService = DeeplinkService()
    } operation: {
      ApplicationFeature.State(userDefaults: userDefaults)
    }
    state.onboardingGeneratedActivityIDs = [activity.id]
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      createPlan: { _, _, _ in
        try await Task.sleep(nanoseconds: 60_000_000_000)
      }
    )

    await store.send(.onboarding(.delegate(.planCreated(draft))))
    await store.send(.onboarding(.delegate(.planCreationCancelled))) {
      $0.onboardingGeneratedActivityIDs = []
    }
    await store.finish()

    #expect(store.state.showOnboarding)
    #expect(!userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func skippedOnboardingCompletesOnboarding() async throws {
    let userDefaults = try makeUserDefaults()
    let store = makeStore(userDefaults: userDefaults)

    await store.send(.onboarding(.delegate(.skipped))) {
      $0.onboarding = OnboardingFeature.State()
      $0.showOnboarding = false
    }

    #expect(userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func creatingOnboardingPlanUsesOnePersistenceTransaction() async throws {
    let userDefaults = try makeUserDefaults()
    let recorder = PlanCreationRecorder()
    var state = ApplicationFeature.State(userDefaults: userDefaults)
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    let startDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))
    )
    let activity = Activity(id: UUID(), name: "Read", startDate: startDate)
    let draft = NewPlanDraft(
      name: "Reading plan",
      duration: .sevenDays,
      startDate: startDate,
      endDate: try #require(calendar.date(byAdding: .day, value: 6, to: startDate)),
      schedule: [ScheduledPlanDay(weekday: .monday, activities: [activity])]
    )
    state.onboardingGeneratedActivityIDs = [activity.id]
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      createPlan: { plan, activities, occurrences in
        await recorder.record(plan, activities: activities, occurrences: occurrences)
      }
    )
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.onboarding(.delegate(.planCreated(draft))))
    await store.receive(.onboardingPlanSaved) {
      $0.onboardingGeneratedActivityIDs = []
      $0.onboarding = OnboardingFeature.State()
      $0.showOnboarding = false
    }

    let creations = await recorder.creations
    let creation = try #require(creations.first)
    #expect(creations.count == 1)
    #expect(creation.activities == [activity])
    #expect(creation.occurrences.count == 1)
    #expect(!store.state.showOnboarding)
    #expect(userDefaults.bool(forKey: "isOnboardingShown"))
  }

  @Test
  func failedOnboardingPlanCreationAllowsRetry() async throws {
    let userDefaults = try makeUserDefaults()
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    let startDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))
    )
    let activity = Activity(id: UUID(), name: "Read", startDate: startDate)
    var planState = NewPlanFeature.State(
      onboardingName: "Reading plan",
      startDate: startDate,
      suggestedActivity: activity,
      scheduledWeekdays: [.monday],
      calendar: calendar
    )
    planState.step = .review
    planState.isSubmitting = true
    var state = ApplicationFeature.State(userDefaults: userDefaults)
    state.onboarding.newPlan = planState
    let draft = NewPlanDraft(
      name: planState.name,
      duration: planState.selectedDuration,
      startDate: planState.startDate,
      endDate: planState.endDate,
      schedule: planState.schedule
    )
    let store = makeStore(
      initialState: state,
      userDefaults: userDefaults,
      createPlan: { _, _, _ in throw PersistenceError.failed }
    )

    await store.send(.onboarding(.delegate(.planCreated(draft))))
    await store.receive(.onboardingPlanSaveFailed) {
      $0.isOnboardingPlanSaveErrorPresented = true
    }
    await store.receive(.onboarding(.newPlan(.submissionFailed))) {
      $0.onboarding.newPlan?.isSubmitting = false
    }
  }

  #if DEBUG
  @Test
  func developerToolsCanShowOnboardingAgain() async throws {
    let userDefaults = try makeUserDefaults()
    userDefaults.set(true, forKey: "isOnboardingShown")
    var state = withDependencies {
      $0.utcCalendar = Calendar(identifier: .gregorian)
      $0.date.now = Date(timeIntervalSinceReferenceDate: 800_000_000)
      $0.uuid = .incrementing
      $0.deeplinkService = DeeplinkService()
    } operation: {
      ApplicationFeature.State(userDefaults: userDefaults)
    }
    state.onboarding = OnboardingFeature.State(selectedGoal: .moveMore)
    state.developerTools = DeveloperToolsFeature.State()
    let store = makeStore(initialState: state, userDefaults: userDefaults)

    await store.send(.developerTools(.presented(.delegate(.showOnboardingAgain)))) {
      $0.onboarding = OnboardingFeature.State()
      $0.showOnboarding = true
      $0.developerTools = nil
    }

    #expect(!userDefaults.bool(forKey: "isOnboardingShown"))
  }
  #endif

  private func makeUserDefaults() throws -> UserDefaults {
    let suiteName = "ApplicationOnboardingTests.\(UUID().uuidString)"
    return try #require(UserDefaults(suiteName: suiteName))
  }

  private func makeStore(
    initialState: ApplicationFeature.State? = nil,
    userDefaults: UserDefaults,
    createPlan: @escaping PlanCreationRepository.Create = { _, _, _ in }
  ) -> TestStoreOf<ApplicationFeature> {
    let calendar = Calendar(identifier: .gregorian).utcCalendar
    return withDependencies {
      $0.calendar = calendar
      $0.utcCalendar = calendar
      $0.date.now = Date(timeIntervalSinceReferenceDate: 800_000_000)
      $0.uuid = .incrementing
      $0.deeplinkService = DeeplinkService()
      $0.planCreationRepository = PlanCreationRepository(create: createPlan)
    } operation: {
      TestStore(
        initialState: initialState ?? ApplicationFeature.State(userDefaults: userDefaults),
        reducer: { ApplicationFeature(userDefaults: userDefaults) }
      )
    }
  }
}

private enum PersistenceError: Error {
  case failed
}

private actor PlanCreationRecorder {
  struct Creation {
    let plan: Plan
    let activities: [Activity]
    let occurrences: [PlanOccurrence]
  }

  private(set) var creations: [Creation] = []

  func record(
    _ plan: Plan,
    activities: [Activity],
    occurrences: [PlanOccurrence]
  ) {
    creations.append(Creation(plan: plan, activities: activities, occurrences: occurrences))
  }
}
