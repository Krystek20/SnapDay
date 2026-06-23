import Models
import struct SwiftUI.Color

public struct ListTrailingMenuItem: Identifiable, Equatable {
  public var id: String { actionId }
  let actionId: String
  let title: String
  let imageName: String
  let subitems: [ListTrailingMenuSubitem]

  public init(
    actionId: String,
    title: String,
    imageName: String,
    subitems: [ListTrailingMenuSubitem] = []
  ) {
    self.actionId = actionId
    self.title = title
    self.imageName = imageName
    self.subitems = subitems
  }
}

public struct ListTrailingMenuSubitem: Identifiable, Equatable {
  public var id: String { itemId }
  let itemId: String
  let actionId: String
  let title: String
  let imageName: String

  public init(
    itemId: String,
    actionId: String,
    title: String,
    imageName: String
  ) {
    self.itemId = itemId
    self.actionId = actionId
    self.title = title
    self.imageName = imageName
  }
}

public struct ListTrailingRowItem: Identifiable, Equatable {
  public var id: String { actionId }
  let actionId: String
  let imageName: String
  let color: Color

  public init(
    actionId: String,
    imageName: String,
    color: Color
  ) {
    self.actionId = actionId
    self.imageName = imageName
    self.color = color
  }
}

public extension ListTrailingRowItem {
  static func accept(actionId: String) -> ListTrailingRowItem {
    ListTrailingRowItem(
      actionId: actionId,
      imageName: "checkmark.circle.fill",
      color: Color.greenSuccess
    )
  }

  static func discard(actionId: String) -> ListTrailingRowItem {
    ListTrailingRowItem(
      actionId: actionId,
      imageName: "xmark.circle.fill",
      color: Color.alertText
    )
  }
}
