import UIKit

final class UIEmojiTextField: UITextField {
  override var textInputMode: UITextInputMode? {
    UITextInputMode.activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
  }
}
