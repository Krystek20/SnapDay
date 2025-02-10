import Foundation
import Models

public struct DayActivityItem: Equatable, Identifiable {

  public enum Icon: String, Identifiable {
    case bell
    case hourglass
    case `repeat`
    case exclamationmark = "exclamationmark.circle.fill"
    case shared = "person.crop.rectangle.stack"

    public var id: String { rawValue }
  }

  public let id: UUID
  let parentId: UUID?
  let title: String
  let subtitle: String
  let iconType: ActivityImageType
  public let isStrikethrough: Bool
  let displayedIcons: [Icon]

  public var isSubtask: Bool { parentId != nil }
}

extension DayActivityItem {
  public init(
    activityType: ActivityType,
    iconData: Data? = nil,
    parentId: UUID? = nil
  ) {
    let isDueDateSet = activityType.dueDaysCount != nil && activityType.dueDaysCount ?? .zero > .zero
    let showHourglass = activityType.dueDate != nil || isDueDateSet
    let iconType: ActivityImageType = if let iconData {
      .data(iconData)
    } else {
      .iconId(activityType.iconId)
    }
    self.init(
      id: activityType.id,
      parentId: parentId,
      title: activityType.name,
      subtitle: activityType.subtitle,
      iconType: iconType,
      isStrikethrough: activityType.isDone,
      displayedIcons: [
        activityType.important ? .exclamationmark : nil,
        showHourglass ? .hourglass : nil,
        activityType.reminderDate != nil ? .bell : nil,
        activityType.isFrequentEnabled ? .repeat : nil,
        activityType.isShared ? .shared : nil
      ].compactMap { $0 }
    )
  }
}

private extension ActivityType {
  var subtitle: String {
    var subtitle = ""
    if let overview, !overview.isEmpty {
      subtitle += overview
    }
    if let duration {
      subtitle += subtitle.isEmpty ? "" : " - "
      subtitle += duration
    }

    return subtitle
  }

  var duration: String? {
    guard duration > .zero else { return nil }
    let minutes = duration % 60
    let hours = duration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }
}
