import ComposableArchitecture
import Foundation
import Models
import Plans
import Repositories
import Testing
@testable import Application

@MainActor
struct DashboardCoordinatorFeatureTests {

  @Test
  func repeatedPlanDeepLinkKeepsLoadedDetails() async throws {
    let plan = makePlan()
    let activity = Activity(id: UUID(), name: "Read")
    let loadedDetails = PlanDetailsFeature.State(
      plan: plan,
      allowsManagement: true,
      activities: [activity]
    )
    let store = withTestDependencies {
      var state = DashboardCoordinatorFeature.State()
      state.path.append(.planDetails(loadedDetails))
      return TestStore(
        initialState: state,
        reducer: { DashboardCoordinatorFeature() }
      )
    }

    await store.send(.externalPlanLoaded(plan))

    #expect(store.state.path.count == 1)
    let pathID = try #require(store.state.path.ids.last)
    let details = try #require(store.state.path[id: pathID, case: \.planDetails])
    #expect(details == loadedDetails)
  }

  @Test
  func planDeepLinkReplacesExistingDashboardDestination() async {
    let plan = makePlan()
    let store = withTestDependencies {
      var state = DashboardCoordinatorFeature.State()
      state.path.append(.plans(PlansFeature.State()))
      return TestStore(
        initialState: state,
        reducer: { DashboardCoordinatorFeature() }
      )
    }

    await store.send(.externalPlanLoaded(plan)) {
      $0.path.removeAll()
      $0.path.append(
        .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
      )
    }

    #expect(store.state.path.count == 1)
  }

  @Test
  func planDetailsPremiumActionContinuesWhenThereIsNoActivePlan() async throws {
    let plan = makePlan()
    var state = withTestDependencies { DashboardCoordinatorFeature.State() }
    state.path.append(
      .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
    )
    let pathID = try #require(state.path.ids.last)
    let store = makeStore(state: state, activePlans: [])

    await store.send(
      .path(.element(
        id: pathID,
        action: .planDetails(.delegate(.premiumAccessRequested))
      ))
    )
    await store.receive(.planLimitResolved(pathID, false))
    await store.receive(
      .path(.element(id: pathID, action: .planDetails(.premiumAccessGranted)))
    )
  }

  @Test
  func planDetailsPremiumActionRequestsPaywallWhenAnotherPlanIsActive() async throws {
    let plan = makePlan()
    var state = withTestDependencies { DashboardCoordinatorFeature.State() }
    state.path.append(
      .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
    )
    let pathID = try #require(state.path.ids.last)
    let store = makeStore(state: state, activePlans: [plan])

    await store.send(
      .path(.element(
        id: pathID,
        action: .planDetails(.delegate(.premiumAccessRequested))
      ))
    )
    await store.receive(.planLimitResolved(pathID, true))
    await store.receive(.delegate(.premiumAccessRequested(.secondActivePlan)))
  }

  private func makePlan() -> Plan {
    let startDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    return withTestDependencies {
      Plan(
        id: UUID(),
        name: "Learn Spanish",
        startDate: startDate,
        endDate: startDate,
        duration: .custom,
        schedule: []
      )
    }
  }

  private func withTestDependencies<T>(_ operation: () -> T) -> T {
    withDependencies {
      $0.utcCalendar = Calendar(identifier: .gregorian)
      $0.date.now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    } operation: {
      operation()
    }
  }

  private func makeStore(
    state: DashboardCoordinatorFeature.State,
    activePlans: [Plan]
  ) -> TestStoreOf<DashboardCoordinatorFeature> {
    TestStore(initialState: state) {
      DashboardCoordinatorFeature()
    } withDependencies: {
      $0.utcCalendar = Calendar(identifier: .gregorian)
      $0.date.now = Date(timeIntervalSinceReferenceDate: 800_000_000)
      $0.planRepository.loadActivePlans = { _ in activePlans }
    }
  }
}
