import SwiftUI
import Resources

struct EmojiTextField: UIViewRepresentable {

  final class Coordinator: NSObject, UITextFieldDelegate {
    var parent: EmojiTextField

    init(parent: EmojiTextField) {
      self.parent = parent
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      let canAddOneEmoji = textField.text?.isEmpty == true
      && string.count == 1
      && !string.unicodeScalars.filter({ $0.properties.isEmoji }).isEmpty

      guard canAddOneEmoji || string.isEmpty else { return false }
      parent.text = string
      return true
    }
  }

  @Binding var text: String

  func makeUIView(context: Context) -> UIEmojiTextField {
    let emojiTextField = UIEmojiTextField()
    emojiTextField.text = text
    emojiTextField.font = UIFont.systemFont(ofSize: 70.0, weight: .bold)
    emojiTextField.textAlignment = .center
    emojiTextField.delegate = context.coordinator
    return emojiTextField
  }

  func updateUIView(_ uiView: UIEmojiTextField, context: Context) {
    uiView.text = text
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }
}
