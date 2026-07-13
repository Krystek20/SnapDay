import ComposableArchitecture
import Foundation
import Testing
@testable import Plans

@MainActor
struct NewPlanFeatureTests {

  @Test
  func selectingPresetUpdatesEndDate() async throws {
    let startDate = try date(year: 2026, month: 6, day: 14)
    let expectedEndDate = try #require(
      Calendar.autoupdatingCurrent.date(
        byAdding: .day,
        value: 14,
        to: startDate
      )
    )
    let store = TestStore(
      initialState: NewPlanFeature.State(startDate: startDate),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.durationTapped(.twoWeeks))) {
      $0.selectedDuration = .twoWeeks
      $0.endDate = expectedEndDate
    }
  }

  @Test
  func changingStartDatePreservesPresetDuration() async throws {
    let initialStartDate = try date(year: 2026, month: 6, day: 14)
    let newStartDate = try date(year: 2026, month: 7, day: 1)
    let expectedEndDate = try #require(
      Calendar.autoupdatingCurrent.date(
        byAdding: .month,
        value: 1,
        to: newStartDate
      )
    )
    let store = TestStore(
      initialState: NewPlanFeature.State(startDate: initialStartDate),
      reducer: { NewPlanFeature() }
    )

    await store.send(.binding(.set(\.$startDate, newStartDate))) {
      $0.startDate = newStartDate
      $0.endDate = expectedEndDate
    }
  }

  @Test
  func customEndDateCannotPrecedeStartDate() async throws {
    let startDate = try date(year: 2026, month: 6, day: 14)
    let earlierDate = try date(year: 2026, month: 6, day: 1)
    let store = TestStore(
      initialState: NewPlanFeature.State(
        selectedDuration: .custom,
        startDate: startDate
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.binding(.set(\.$endDate, earlierDate))) {
      $0.endDate = startDate
    }
  }

  @Test
  func createPlanButtonDelegatesNavigation() async {
    let store = TestStore(
      initialState: PlansFeature.State(),
      reducer: { PlansFeature() }
    )

    await store.send(.view(.createPlanButtonTapped))
    await store.receive(.delegate(.createPlanTapped))
  }

  @Test
  func cancelDelegatesDismissal() async {
    let store = TestStore(
      initialState: NewPlanFeature.State(),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.cancelButtonTapped))
    await store.receive(.delegate(.cancelTapped))
  }

  private func date(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
      Calendar.autoupdatingCurrent.date(
        from: DateComponents(year: year, month: month, day: day, hour: 12)
      )
    )
  }
}
