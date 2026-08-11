import ComposableArchitecture
import Foundation
import Models
import Plans
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
    var state = DashboardCoordinatorFeature.State()
    state.path.append(.planDetails(loadedDetails))
    let store = TestStore(
      initialState: state,
      reducer: { DashboardCoordinatorFeature() }
    )

    await store.send(.externalPlanLoaded(plan))

    #expect(store.state.path.count == 1)
    let pathID = try #require(store.state.path.ids.last)
    let details = try #require(store.state.path[id: pathID, case: \.planDetails])
    #expect(details == loadedDetails)
  }

  @Test
  func planDeepLinkReplacesExistingDashboardDestination() async {
    let plan = makePlan()
    var state = DashboardCoordinatorFeature.State()
    state.path.append(.plans(PlansFeature.State()))
    let store = TestStore(
      initialState: state,
      reducer: { DashboardCoordinatorFeature() }
    )

    await store.send(.externalPlanLoaded(plan)) {
      $0.path.removeAll()
      $0.path.append(
        .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
      )
    }

    #expect(store.state.path.count == 1)
  }

  private func makePlan() -> Plan {
    let startDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    return Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: startDate,
      endDate: startDate,
      duration: .custom,
      schedule: []
    )
  }
}
