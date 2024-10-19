import SwiftUI

fileprivate struct Draggable: ViewModifier {

  let condition: Bool
  let data: () -> NSItemProvider

  @ViewBuilder
  func body(content: Content) -> some View {
    if condition {
      content.onDrag(data)
    } else {
      content
    }
  }
}

extension View {
  public func drag(if condition: Bool, data: @escaping () -> NSItemProvider) -> some View {
    modifier(Draggable(condition: condition, data: data))
  }
}
