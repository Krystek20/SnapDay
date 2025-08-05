import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities

@MainActor
public struct FriendsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<FriendsFeature>
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
        .sheet(isPresented: $store.showContactList, content: {
          ContactViewWrapper(
            isPresented: $store.showContactList,
            onSelect: { contacts in
              store.send(.view(.contactsSelected(contacts)))
            }
          )
        })
        .navigationTitle(String(localized: "Friends", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .bind($store.focus, to: $focus)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            HStack {
              Button(
                action: {
                  store.send(.view(.showContactList))
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
      VStack(spacing: 10.0) {
        if store.isGeneratingInvitiation {
          InformationView(configuration: InformationViewConfiguration.generatingUrl)
            .formBackgroundModifier(padding: EdgeInsets(.zero))
            .padding(.horizontal, 15.0)
        }

        switch store.content {
        case .list, .form:
          ScrollView {
            participantsSection
              .padding(.horizontal, 15.0)
              .padding(.bottom, 15.0)
          }
          .scrollDismissesKeyboard(.immediately)
          .scrollIndicators(.hidden)
        case .noCollaboration:
          VStack {
            InformationView(configuration: InformationViewConfiguration.addFriends)
              .formBackgroundModifier(padding: EdgeInsets(.zero))
              .padding(.horizontal, 15.0)
            Spacer()
          }
        case .empty:
          Spacer()
        case .loading:
          Spacer()
          ProgressView()
            .maxWidth(alignment: .center)
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
          if !store.collaborations.isEmpty {
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
        ForEach(store.collaborations) { collaboration in
          HStack(alignment: .center, spacing: 10.0) {
            Image(systemName: collaboration.iconName)
              .iconable(color: collaboration.color)
            VStack(alignment: .leading, spacing: 2.0) {
              Text(collaboration.title)
                .font(.system(size: 14.0, weight: .regular))
              if let subtitle = collaboration.subtitle {
                Text(subtitle)
                  .font(.system(size: 12.0, weight: .regular))
              }
              Text(collaboration.description)
                .font(.system(size: 12.0, weight: .regular))
            }
            .foregroundStyle(Color.standardText)
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack(spacing: 10.0) {
              TrailingIcon.moreIcon
                .overlay {
                  menuView(collaboration: collaboration)
                }
            }
          }
          .padding(.horizontal, 5.0)

          if collaboration != store.collaborations.last {
            Divider()
          }
        }
      }
    }
  }

  private func menuView(collaboration: Collaboration) -> some View {
    Menu {
      reinviteButton(collaboration: collaboration)
      removeButton(collaboration: collaboration)
    } label: {
      Color.clear
        .frame(width: 30.0, height: 30.0)
    }
  }

  private func reinviteButton(collaboration: Collaboration) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.reinviteButtonTapped(collaboration)))
        },
        label: {
          Text("Reinvite", bundle: .module)
          Image(systemName: "arrow.clockwise.circle")
        }
      )
    }
  }

  private func removeButton(collaboration: Collaboration) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.removeButtonTapped(collaboration)))
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
    }
  }
}
