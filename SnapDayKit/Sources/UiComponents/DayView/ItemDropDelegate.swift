import Dependencies
import Models
import SwiftUI

struct ItemDropDelegate: DropDelegate {

  let destinationItem: DayActivity
  @Binding var draggedItem: DayActivity?

  var moveAction: (_ draggedItem: DayActivity) -> Void
  var performDrop: () -> Void

  // MARK: - Dependecies

  @Dependency(\.calendar) private var calendar

  func dropUpdated(info: DropInfo) -> DropProposal? {
    guard let draggedItem else { return DropProposal(operation: .cancel) }
    return canMove(item: draggedItem)
    ? DropProposal(operation: .move)
    : DropProposal(operation: .cancel)
  }

  func performDrop(info: DropInfo) -> Bool {
    guard let draggedItem else { return false }
    let moved = canMove(item: draggedItem)
    if moved {
      performDrop()
      self.draggedItem = nil
    }
    return moved
  }

  func dropEntered(info: DropInfo) {
    guard let draggedItem, canMove(item: draggedItem) else { return }
    moveAction(draggedItem)
  }

  private func canMove(item: DayActivity) -> Bool {
    item.priority(calendar: calendar) == destinationItem.priority(calendar: calendar)
  }
}
