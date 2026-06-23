import SwiftUI

private struct OnActionModifier: ViewModifier {
  let handler: (String, ListItem) -> Void

  func body(content: Content) -> some View {
    content.environment(\.actionHandler, handler)
  }
}

public extension View {
  func onListItemAction(
    _ handler: @escaping (String, ListItem) -> Void
  ) -> some View {
    modifier(
      OnActionModifier { identifier, listItem in
        handler(identifier, listItem)
      }
    )
  }
}
