import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities
import ContactList

@MainActor
public struct FriendsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<FriendsFeature>
  @State private var participantItemHeight: CGFloat = .zero
  @State private var isLoading = false
  @FocusState private var focus: FriendsField?

  // MARK: - Initialization

  public init(store: StoreOf<FriendsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      content
        .maxWidth()
        .activityBackground
        .onAppear {
          store.send(.view(.appeared))
        }
        .sheet(isPresented: $store.isSharing) {
          if let shareResult = store.shareResult {
            ShareSheet(
              isShared: $store.isSharing,
              shareResult: shareResult
            )
          }
        }
        .sheet(item: $store.scope(state: \.contactList, action: \.contactList)) { store in
          NavigationStack {
            ContactListView(store: store)
          }
          .presentationDetents([.large])
        }
        .navigationTitle(String(localized: "Friends", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .bind($store.focus, to: $focus)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            HStack {
              Button(
                action: {
                  store.send(.view(.showContacts))
                },
                label: {
                  Image(systemName: "list.bullet.circle.fill")
                    .foregroundStyle(Color.actionBlue)
                }
              )
              Button(
                action: {
                  store.send(.view(.newButtonTapped))
                },
                label: {
                  Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.actionBlue)
                }
              )
            }
          }
        }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      VStack(alignment: .center, spacing: 10.0) {
        Picker("", selection: $store.listType) {
          WithPerceptionTracking {
            ForEach(FriendsFeature.ListType.allCases) { listType in
              Text(listType.title).tag(listType)
            }
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 15.0)

        switch store.content {
        case .list, .form:
          ScrollView {
            participantsSection
              .padding(.horizontal, 15.0)
              .padding(.bottom, 15.0)
          }
          .scrollDismissesKeyboard(.immediately)
          .scrollIndicators(.hidden)
        case .empty(let emptyListText):
          Spacer()
          VStack(spacing: 10.0) {
            Image(systemName: "envelope")
              .font(.system(size: 40.0, weight: .ultraLight))
            Text(emptyListText)
              .font(.system(size: 14.0, weight: .regular))
              .multilineTextAlignment(.center)
              .foregroundStyle(Color.standardText)
              .padding(.horizontal, 30.0)
          }
          Spacer()
        case .appending:
          Spacer()
          VStack(spacing: 10.0) {
            Image(systemName: "paperplane.fill")
              .font(.system(size: 40))
              .offset(y: isLoading ? -20.0 : .zero)
              .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isLoading)
              .onAppear { isLoading = true }
              .onDisappear { isLoading = false }
            Text("Preparing invitation", bundle: .module)
              .font(.system(size: 14.0, weight: .regular))
              .multilineTextAlignment(.center)
              .foregroundStyle(Color.standardText)
              .padding(.horizontal, 30.0)
          }
          Spacer()
        case .loading:
          Spacer()
          ProgressView()
          Spacer()
        }
      }
    }
  }

  private var participantsSection: some View {
    WithPerceptionTracking {
      VStack {
        if store.content == .form {
          inviteFriendsView
          if !store.participants.isEmpty {
            Divider()
          }
        }

        if store.content == .list || store.content == .form {
          participantList
        }
      }
      .formBackgroundModifier()
    }
  }

  private var participantList: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 10.0) {
        ForEach(store.participants) { participant in
          HStack(alignment: .center, spacing: 5.0) {
            VStack(alignment: .leading, spacing: 2.0) {
              if !participant.name.isEmpty {
                Text(participant.name)
              }
              Text(participant.value)
            }
            .font(.system(size: 14.0, weight: .regular))
            .lineLimit(1)
            .foregroundStyle(Color.standardText)

            Spacer()

            HStack(spacing: 10.0) {
              participantIcon(status: participant.acceptanceStatus)
              TrailingIcon.moreIcon
                .overlay {
                  menuView(participant: participant)
                }
            }
          }
          .maxDynamic(height: $participantItemHeight, minHeight: 36.0)

          if participant != store.participants.last {
            Divider()
          }
        }
      }
    }
  }

  private func participantIcon(status: ParticipantAcceptanceStatus) -> some View {
    let (image, color) = switch status {
    case .unknown:
      (Image(systemName: "questionmark.circle"), Color.sectionText)
    case .pending:
      (Image(systemName: "clock.circle"), Color.sectionText)
    case .accepted:
      (Image(systemName: "checkmark.circle"), Color.greenSuccess)
    case .removed:
      (Image(systemName: "xmark.circle"), Color.alertText)
    }
    return image.iconable(color: color)
  }

  private func menuView(participant: Participant) -> some View {
    Menu {
      if participant.type == .invited {
        reinviteButton(participant: participant)
      }
      removeButton(participant: participant)
    } label: {
      Color.clear
        .frame(width: 30.0, height: 30.0)
    }
  }

  private func reinviteButton(participant: Participant) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.reinviteButtonTapped(participant)))
        },
        label: {
          Text("Reinvite", bundle: .module)
          Image(systemName: "arrow.clockwise.circle")
        }
      )
    }
  }

  private func removeButton(participant: Participant) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.removeButtonTapped(participant)))
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    }
  }

  private var inviteFriendsView: some View {
    WithPerceptionTracking {
      HStack(alignment: .center, spacing: 5.0) {
        TextField(String(localized: "Email or phone number", bundle: .module), text: $store.contact)
          .font(.system(size: 14.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.standardText)
          .submitLabel(.done)
          .focused($focus, equals: .addNew)

        Spacer()

        HStack(spacing: 10.0) {
          if store.isAddCollaboratorInviteEnabled {
            Button(String(localized: "Add", bundle: .module), action: {
              store.send(.view(.inviteButtonTapped))
            })
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.actionBlue)
          }

          Button(String(localized: "Cancel", bundle: .module), action: {
            store.send(.view(.cancelButtonTapped))
          })
          .font(.system(size: 12.0, weight: .bold))
          .foregroundStyle(Color.actionBlue)
        }
      }
      .maxDynamic(height: $participantItemHeight, minHeight: 36.0)
    }
  }
}
