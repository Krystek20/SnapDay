import Contacts

public enum ContactViewType {
  case list
  case allowButton
  case daniedInformation
}

public struct Contact: Identifiable, Equatable {
  public let id: String
  let givenName: String
  let familyName: String
  public let emails: [String]
  public let phoneNumbers: [String]
  public var preferredContact: String

  public var values: [String] {
    emails + phoneNumbers
  }

  init(
    id: String,
    givenName: String,
    familyName: String,
    emails: [String],
    phoneNumbers: [String],
    preferredContact: String
  ) {
    self.id = id
    self.givenName = givenName
    self.familyName = familyName
    self.emails = emails
    self.phoneNumbers = phoneNumbers
    self.preferredContact = preferredContact
  }

  init?(contact: CNContact) {
    let emails = contact.emailAddresses.map { $0.value as String }
    let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
    guard !emails.isEmpty || !phoneNumbers.isEmpty else { return nil }
    let preferredContact = emails.first ?? phoneNumbers.first ?? ""

    self.init(
      id: contact.identifier,
      givenName: contact.givenName,
      familyName: contact.familyName,
      emails: emails,
      phoneNumbers: phoneNumbers,
      preferredContact: preferredContact
    )
  }

  public var name: String {
    switch (givenName.isEmpty, familyName.isEmpty) {
    case (true, true):
      ""
    case (true, false):
      familyName
    case (false, true):
      givenName
    case (false, false):
      givenName + " " + familyName
    }
  }
}
