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
}
