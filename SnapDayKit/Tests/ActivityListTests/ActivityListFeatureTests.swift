import ComposableArchitecture
import Foundation
import Models
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
}
