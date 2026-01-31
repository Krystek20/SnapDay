import Foundation
import Models
import Utilities

public struct ListItem: Equatable, Identifiable {

  public enum Icon: String, Identifiable {
    case bell = "bell.circle.fill"
    case hourglass = "hourglass.circle.fill"
    case `repeat` = "repeat.circle.fill"
    case exclamationmark = "exclamationmark.circle.fill"

    public var id: String { rawValue }
  }

  public enum DividerType: Equatable {
    case full
    case aligned
    case indented
    case none
  }

  public enum FieldType: Equatable {
    case text
    case textEdit
  }

  public enum Trailing: Equatable {
    case none
    case row([ListTrailingRowItem])
    case menu([ListTrailingMenuItem])
  }

  public enum Progress: Equatable {
    case none
    case line(value: Double, total: Double)
  }

  public struct Participant: Equatable, Identifiable {
    public let id: String
    let name: String

    public init(id: String, name: String) {
      self.id = id
      self.name = name
    }

    var initials: String {
      let components = name.split(separator: " ").prefix(2)
      return components.map { String($0.first ?? Character("")) }.joined().uppercased()
    }

    var backgroundColor: RGBColor {
      let hash = stableHash(id)
      return RGBColor(
        red: Double((hash >> 16) & 0xFF) / 255.0,
        green: Double((hash >> 8) & 0xFF) / 255.0,
        blue: Double(hash & 0xFF) / 255.0,
        alpha: 1.0
      )
    }

    private func stableHash(_ input: String) -> UInt32 {
      var hash: UInt32 = 5381
      for byte in input.utf8 {
        hash = ((hash << 5) &+ hash) &+ UInt32(byte)
      }
      return hash
    }
  }

  public let id: String
  let parentId: String?
  let headerItem: ListViewHeaderItem?
  public internal(set) var title: String
  let subtitle: String
  let fieldType: FieldType
  let iconType: ImageType
  public let isStrikethrough: Bool
  let displayedIcons: [Icon]
  let participants: [Participant]
  let divider: DividerType
  var focus: String?
  let isDraggable: Bool
  let priority: Priority
  let trailing: Trailing
  let progress: Progress

  public var isSubtask: Bool { parentId != nil }
  public var isForm: Bool { fieldType == .textEdit }

  public init(
    id: String,
    parentId: String?,
    headerItem: ListViewHeaderItem?,
    title: String,
    subtitle: String,
    fieldType: FieldType,
    iconType: ImageType,
    isStrikethrough: Bool,
    displayedIcons: [Icon],
    participants: [Participant],
    divider: DividerType,
    focus: String? = nil,
    isDraggable: Bool,
    priority: Priority,
    trailing: Trailing,
    progress: Progress
  ) {
    self.id = id
    self.parentId = parentId
    self.headerItem = headerItem
    self.title = title
    self.subtitle = subtitle
    self.fieldType = fieldType
    self.iconType = iconType
    self.isStrikethrough = isStrikethrough
    self.displayedIcons = displayedIcons
    self.participants = participants
    self.divider = divider
    self.focus = focus
    self.isDraggable = isDraggable
    self.priority = priority
    self.trailing = trailing
    self.progress = progress
  }
}

extension ListItem {
  public static func form(
    id: String,
    focus: String,
    divider: DividerType,
    iconType: ImageType = .placeholder,
    parentId: String? = nil
  ) -> ListItem {
    ListItem(
      id: id,
      parentId: parentId,
      headerItem: nil,
      title: "",
      subtitle: "",
      fieldType: .textEdit,
      iconType: iconType,
      isStrikethrough: false,
      displayedIcons: [],
      participants: [],
      divider: divider,
      focus: focus,
      isDraggable: false,
      priority: .normal,
      trailing: .none,
      progress: .none
    )
  }
}
