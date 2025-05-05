import Foundation
import Dependencies
import Contacts

extension DependencyValues {
  public var contactsProvider: ContactsProvider {
    get { self[ContactsProvider.self] }
    set { self[ContactsProvider.self] = newValue }
  }
}

extension ContactsProvider: DependencyKey {
  public static var liveValue: ContactsProvider {
    ContactsProvider()
  }
}

public struct ContactsProvider {

  public var state: ContactsState {
    switch CNContactStore.authorizationStatus(for: .contacts) {
    case .authorized, .limited:
        .allowed
    case .notDetermined:
        .notDetermined
    case .restricted, .denied:
        .notAllowed
    @unknown default:
        .notAllowed
    }
  }

  public func loadContacts() throws -> [Contact] {
    let store = CNContactStore()
    let keys = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactEmailAddressesKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor
    ]
    return try store.unifiedContacts(
      matching: NSPredicate(value: true),
      keysToFetch: keys
    )
    .compactMap(Contact.init)
  }
}
