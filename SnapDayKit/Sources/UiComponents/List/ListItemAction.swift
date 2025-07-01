import Models

public enum ListItemAction: Equatable {

  case itemTapped(itemId: String, parentId: String?)

  public enum ReorderAction: Equatable {
    case perform(destinationId: String)
    case drop
  }

  case reorder(ReorderAction, String)

  case newItemForm(NewItemFormAction)

  public struct RowParameters: Equatable {
    public let actionId: String
    public let itemId: String
  }

  case rowAction(RowParameters)

  public struct MenuParameters: Equatable {
    public let actionId: String
    public let itemId: String
    public let parentId: String?
  }

  public struct SubmenuParameters: Equatable {
    public let actionId: String
    public let itemId: String
  }

  case menuAction(menuParameters: MenuParameters, submenuParameters: SubmenuParameters?)
}
