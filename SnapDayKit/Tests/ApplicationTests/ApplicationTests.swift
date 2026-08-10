import ComposableArchitecture
import Foundation
import Models
import Plans
import Testing
@testable import Application

@MainActor
struct ApplicationFeatureTests {

  @Test
  func repeatedPlanDeepLinkDoesNotDuplicatePlanDestination() async {
    let plan = makePlan()
    let store = TestStore(
      initialState: ApplicationFeature.State(),
      reducer: { ApplicationFeature() }
    )

    await store.send(.planDeepLinkLoaded(plan)) {
      $0.dashboardPath.append(
        .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
      )
    }
    await store.send(.planDeepLinkLoaded(plan)) {
      $0.dashboardPath.removeAll()
      $0.dashboardPath.append(
        .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
      )
    }

    #expect(store.state.dashboardPath.count == 1)
  }

  @Test
  func planDeepLinkReplacesExistingDashboardDestination() async {
    let plan = makePlan()
    var state = ApplicationFeature.State()
    state.dashboardPath.append(.plans(PlansFeature.State()))
    let store = TestStore(
      initialState: state,
      reducer: { ApplicationFeature() }
    )

    await store.send(.planDeepLinkLoaded(plan)) {
      $0.dashboardPath.removeAll()
      $0.dashboardPath.append(
        .planDetails(PlanDetailsFeature.State(plan: plan, allowsManagement: true))
      )
    }

    #expect(store.state.dashboardPath.count == 1)
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
