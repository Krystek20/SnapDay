import Foundation
import ComposableArchitecture
import Testing
@testable import Friends

@MainActor
struct FriendsPremiumTests {

  @Test
  func freeInvitationPreservesRecipientAndRequestsPremiumAccess() async {
    var state = FriendsFeature.State()
    state.contact = "friend@example.com"
    let store = TestStore(
      initialState: state,
      reducer: { FriendsFeature() }
    )

    await store.send(.view(.inviteButtonTapped)) {
      $0.pendingInvitation = [
        FriendsFeature.State.InvitationRecipient(
          email: "friend@example.com",
          phoneNumber: ""
        )
      ]
    }
    await store.receive(.delegate(.premiumAccessRequested))
  }

  @Test
  func entitlementUpdatesDoNotDiscardPendingInvitation() async {
    var state = FriendsFeature.State()
    state.pendingInvitation = [
      FriendsFeature.State.InvitationRecipient(
        email: "friend@example.com",
        phoneNumber: ""
      )
    ]
    let store = TestStore(
      initialState: state,
      reducer: { FriendsFeature() }
    )

    await store.send(.premiumEntitlementUpdated(false))
    #expect(store.state.pendingInvitation == state.pendingInvitation)
  }

  @Test
  func invitationTimeoutStopsLoadingAndShowsAnError() async {
    let attemptID = UUID()
    var state = FriendsFeature.State(hasPremiumAccess: true)
    state.invitationAttemptID = attemptID
    state.isGeneratingInvitiation = true
    state.content = .empty

    let store = TestStore(
      initialState: state,
      reducer: { FriendsFeature() }
    )

    await store.send(.internal(.invitationTimedOut(attemptID))) {
      $0.invitationAttemptID = nil
      $0.isGeneratingInvitiation = false
      $0.content = .noCollaboration
      $0.showInvitationError = true
    }
  }

  @Test
  func invitationAlreadyInProgressIgnoresAnotherInvite() async {
    let attemptID = UUID()
    var state = FriendsFeature.State(hasPremiumAccess: true)
    state.contact = "friend@example.com"
    state.invitationAttemptID = attemptID
    state.isGeneratingInvitiation = true

    let store = TestStore(
      initialState: state,
      reducer: { FriendsFeature() }
    )

    await store.send(.view(.inviteButtonTapped))
    #expect(store.state.invitationAttemptID == attemptID)
    #expect(store.state.isGeneratingInvitiation)
  }

  @Test
  func participantRefreshDoesNotStopInvitationInProgress() async {
    let attemptID = UUID()
    var state = FriendsFeature.State(hasPremiumAccess: true)
    state.invitationAttemptID = attemptID
    state.isGeneratingInvitiation = true
    state.content = .empty

    let store = TestStore(
      initialState: state,
      reducer: { FriendsFeature() }
    )

    await store.send(.internal(.setCollaborations([])))
    await store.receive(.internal(.setViewContent(.noCollaboration))) {
      $0.content = .noCollaboration
    }
    #expect(store.state.invitationAttemptID == attemptID)
    #expect(store.state.isGeneratingInvitiation)
  }
}
