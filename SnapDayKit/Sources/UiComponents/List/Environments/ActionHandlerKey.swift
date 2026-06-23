import SwiftUI

private struct ActionHandlerKey: EnvironmentKey {
  static let defaultValue: ((String, ListItem) -> Void)? = nil
}

extension EnvironmentValues {
  var actionHandler: ((String, ListItem) -> Void)? {
    get { self[ActionHandlerKey.self] }
    set { self[ActionHandlerKey.self] = newValue }
  }
}
