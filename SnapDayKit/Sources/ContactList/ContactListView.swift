import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities
import ContactsUI

@MainActor
public struct ContactListView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ContactListFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ContactListFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          contactsSection
            .padding(.horizontal, 15.0)
            .padding(.bottom, 15.0)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .maxWidth()
      }
      .activityBackground
      .task {
        store.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Contacts", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var contactsSection: some View {
    WithPerceptionTracking {
      switch store.contactViewType {
      case .allowButton:
        showContactsButton
      case .list:
        contactOrLoaderList
      case .daniedInformation:
        Text("daniedInformation", bundle: .module)
      }
    }
  }

  private var showContactsButton: some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.showContactsTapped))
        },
        label: {
          Text("Show Contacts", bundle: .module)
            .foregroundStyle(Color.actionBlue)
            .font(.system(size: 12.0, weight: .bold))
        }
      )
      .maxFrame(alignment: .center)
      .formBackgroundModifier()
    }
  }

  private var contactOrLoaderList: some View {
    WithPerceptionTracking {
      if store.contacts.isEmpty {
        Text("Contacts not found", bundle: .module)
          .font(.system(size: 14.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.standardText)
          .maxFrame()
          .formBackgroundModifier()
      } else {
        contactList
          .formBackgroundModifier()
      }
    }
  }

  private var contactList: some View {
    WithPerceptionTracking {
      LazyVStack(alignment: .leading, spacing: 10.0) {
        ForEach(store.contacts) { contact in
          contactCell(contact)
          if contact != store.contacts.last {
            Divider()
          }
        }
      }
    }
  }

  private func contactCell(_ contact: Contact) -> some View {
    WithPerceptionTracking {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 2.0) {
          Text(contact.name.isEmpty ? contact.preferredContact :  contact.name)
            .font(.system(size: 14.0, weight: .regular))
            .lineLimit(1)
            .foregroundStyle(Color.standardText)

          Menu(
            content: {
              ForEach(contact.values, id: \.self) { value in
                Button(
                  action: {
                    store.send(.view(.changedPreferedContact(contact, value)))
                  },
                  label: {
                    Text(value)
                      .font(.system(size: 14.0, weight: .regular))
                      .lineLimit(1)
                      .foregroundStyle(Color.standardText)
                  }
                )
              }
            }, label: {
              Text(contact.preferredContact)
                .font(.system(size: 14.0, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(Color.actionBlue)
            }
          )
        }

        Spacer()

        Button(
          action: {
            store.send(.view(.inviteTapped(contact)))
          },
          label: {
            Image(systemName: "plus.circle")
              .foregroundStyle(Color.actionBlue)
          }
        )
      }
    }
  }
}
