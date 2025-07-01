import SwiftUI
import Resources
import Models

public struct ListView: View {

  // MARK: - Properties

  @Binding private var items: [ListItem]
  private let completedActivities: CompletedActivities
  private let action: (ListItemAction) -> Void

  @State private var draggedActivity: ListItem?

  // MARK: - Initialization

  public init(
    items: Binding<[ListItem]>,
    completedActivities: CompletedActivities,
    action: @escaping (ListItemAction) -> Void
  ) {
    self._items = items
    self.completedActivities = completedActivities
    self.action = action
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: .zero) {
      ForEach($items, content: menuActivityView)
      doneRowViewIfNeeded()
    }
  }

  private func menuActivityView(_ item: Binding<ListItem>) -> some View {
    ListItemView(item: item, action: action)
      .contentShape(Rectangle())
      .onTapGesture {
        action(.itemTapped(itemId: item.id, parentId: item.wrappedValue.parentId))
      }
      .drag(if: item.wrappedValue.isDraggable, data: {
        draggedActivity = item.wrappedValue
        return NSItemProvider()
      })
      .onDrop(
        of: [.text],
        delegate: ItemDropDelegate(
          destinationItem: item.wrappedValue,
          draggedItem: $draggedActivity,
          moveAction: { dragged in
            action(.reorder(.perform(destinationId: item.id), dragged.id))
          },
          performDrop: {
            action(.reorder(.drop, item.id))
          }
        )
      )
  }

  @ViewBuilder
  private func doneRowViewIfNeeded() -> some View {
    if !items.isEmpty {
      CompletedActivitiesView(completedActivities: completedActivities)
    }
  }
}
