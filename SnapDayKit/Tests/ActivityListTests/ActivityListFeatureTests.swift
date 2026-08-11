import ComposableArchitecture
import Foundation
import Models
@testable import Repositories
import Testing
@testable import ActivityList

@MainActor
struct ActivityListFeatureTests {

  @Test
  func selectionModeTogglesAndConfirmsActivities() async throws {
    let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let first = Activity(id: firstID, name: "Read")
    let second = Activity(id: secondID, name: "Walk")
    var initialState = ActivityListFeature.State(
      selectedActivityIDs: [firstID],
      title: "Add to Monday"
    )
    initialState.activities = [first, second]
    let store = TestStore(
      initialState: initialState,
      reducer: { ActivityListFeature() }
    )

    await store.send(.view(.activitySelectionTapped(secondID))) {
      $0.selectedActivityIDs = [firstID, secondID]
    }
    await store.send(.view(.selectionConfirmed))
    await store.receive(.delegate(.selectionConfirmed([first, second])))
  }

  @Test
  func activityUsedByPlanCannotBeDeleted() async throws {
    let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let activity = Activity(id: UUID(), name: "Read")
    let plan = Plan(
      id: UUID(),
      name: "Reading",
      startDate: date,
      endDate: date,
      duration: .custom,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .monday,
          activityID: activity.id,
          position: 0
        )
      ]
    )
    let store = withDependencies {
      $0.planRepository = PlanRepository(
        loadPlans: { [plan] },
        loadActivePlans: { _ in [] },
        loadHistoricalPlans: { _ in [] },
        plan: { _ in nil },
        savePlan: { _ in },
        archivePlan: { _ in },
        loadOccurrences: { _ in [] },
        saveOccurrences: { _ in },
        synchronizeOccurrences: { _, _ in [] }
      )
    } operation: {
      TestStore(
        initialState: ActivityListFeature.State(
          day: Day(id: UUID(), date: date, activities: [])
        ),
        reducer: { ActivityListFeature() }
      )
    }

    await store.send(.internal(.removeDayActivities(activity)))
    await store.receive(.internal(.activityDeletionBlocked)) {
      $0.isPlanActivityDeletionAlertPresented = true
    }
  }
}
