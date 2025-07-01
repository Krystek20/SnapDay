import Dependencies
import Models
import SwiftUI

struct ItemDropDelegate: DropDelegate {

  let destinationItem: ListItem
  @Binding var draggedItem: ListItem?

  var moveAction: (_ draggedItem: ListItem) -> Void
  var performDrop: () -> Void

  func dropUpdated(info: DropInfo) -> DropProposal? {
    guard let draggedItem else { return DropProposal(operation: .cancel) }
    return draggedItem.priority == destinationItem.priority
    ? DropProposal(operation: .move)
    : DropProposal(operation: .cancel)
  }

  func performDrop(info: DropInfo) -> Bool {
    guard let draggedItem else { return false }
    let moved = draggedItem.priority == destinationItem.priority
    if moved {
      performDrop()
      self.draggedItem = nil
    }
    return moved
  }

  func dropEntered(info: DropInfo) {
    guard let draggedItem, draggedItem.priority == destinationItem.priority else { return }
    moveAction(draggedItem)
  }
}
