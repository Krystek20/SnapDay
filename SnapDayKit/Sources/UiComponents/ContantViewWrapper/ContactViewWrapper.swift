import SwiftUI
import ContactsUI

public struct ContactViewWrapper: UIViewControllerRepresentable {

  @Binding var isPresented: Bool
  var onSelect: ([CNContact]) -> Void = { _ in }

  public init(
    isPresented: Binding<Bool>,
    onSelect: @escaping ([CNContact]) -> Void
  ) {
    self._isPresented = isPresented
    self.onSelect = onSelect
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public func makeUIViewController(context: Context) -> CNContactPickerViewController {
    let picker = CNContactPickerViewController()
    picker.delegate = context.coordinator
    picker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 OR phoneNumbers.@count > 0")
    picker.displayedPropertyKeys = [
      CNContactPhoneNumbersKey,
      CNContactEmailAddressesKey
    ]
    return picker
  }

  public func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) { }

  public class Coordinator: NSObject, CNContactPickerDelegate {
    let parent: ContactViewWrapper

    init(parent: ContactViewWrapper) {
      self.parent = parent
    }

    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
      parent.onSelect(contacts)
    }
  }
}
