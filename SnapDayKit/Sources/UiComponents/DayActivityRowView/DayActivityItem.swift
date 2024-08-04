import Foundation
import Models

public struct DayActivityItem: Equatable, Identifiable {

  public enum Icon: String, Identifiable {
    case bell
    case hourglass

    public var id: String { rawValue }
  }

  public let id: UUID
  let parentId: UUID?
  let title: String
  let subtitle: String
  let iconData: Data?
  public let isStrikethrough: Bool
  let displayedIcons: [Icon]

  public var isSubtask: Bool { parentId != nil }
}

extension DayActivityItem {
  public init(
    activityType: ActivityType,
    parentId: UUID? = nil
  ) {
    let isDueDateSet = activityType.dueDaysCount != nil && activityType.dueDaysCount ?? .zero > .zero
    let showHourglass = activityType.dueDate != nil || isDueDateSet
    self.init(
      id: activityType.id,
      parentId: parentId,
      title: activityType.name,
      subtitle: activityType.subtitle,
      iconData: activityType.icon?.data,
      isStrikethrough: activityType.isDone,
      displayedIcons: [
        showHourglass ? .hourglass : nil,
        activityType.reminderDate != nil ? .bell : nil
      ].compactMap { $0 }
    )
  }
}

private extension ActivityType {
  var subtitle: String {
    var subtitle = ""
    if let overview = overview, !overview.isEmpty {
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
