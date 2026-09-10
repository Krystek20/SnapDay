import ComposableArchitecture
import Foundation
import Models
import Testing
@testable import DayActivityForm

@MainActor
struct DayActivityFormPremiumTests {

  @Test
  func premiumFrequencySelectionResumesAfterAccessIsGranted() async {
    let monthly = ActivityFrequency.monthly(monthlySchedule: .firstDay)
    let store = TestStore(
      initialState: DayActivityFormFeature.State(
        form: DayActivityForm(activity: Activity(id: UUID(), name: "Read")),
        type: .edit,
        editDate: .now
      ),
      reducer: { DayActivityFormFeature() }
    )

    await store.send(.view(.frequencySelected(monthly))) {
      $0.pendingPremiumAction = .selectFrequency(monthly)
    }
    await store.receive(.delegate(.premiumAccessRequested))

    await store.send(.premiumAccessGranted) {
      $0.hasPremiumAccess = true
      $0.pendingPremiumAction = nil
      $0.form.frequency = monthly
    }
  }

  @Test
  func existingPremiumFrequencyDoesNotRequireAccessUntilChanged() {
    let monthly = ActivityFrequency.monthly(monthlySchedule: .firstDay)
    let state = DayActivityFormFeature.State(
      form: DayActivityForm(
        activity: Activity(id: UUID(), name: "Read", frequency: monthly)
      ),
      type: .edit,
      editDate: .now
    )

    #expect(state.requiresPremiumAccessToSave == false)
  }

  @Test
  func reEnablingExistingPremiumFrequencyRequiresAccess() {
    let monthly = ActivityFrequency.monthly(monthlySchedule: .firstDay)
    var state = DayActivityFormFeature.State(
      form: DayActivityForm(
        activity: Activity(
          id: UUID(),
          name: "Read",
          frequency: monthly,
          isFrequentEnabled: false
        )
      ),
      type: .edit,
      editDate: .now
    )

    state.form.isFrequentEnabled = true

    #expect(state.requiresPremiumAccessToSave)
  }
}
