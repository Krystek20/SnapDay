import Foundation
import Models

public struct DayActivityItem: Equatable, Identifiable {

  public enum Icon: String, Identifiable {
    case bell = "bell.circle.fill"
    case hourglass = "hourglass.circle.fill"
    case `repeat` = "repeat.circle.fill"
    case exclamationmark = "exclamationmark.circle.fill"

    public var id: String { rawValue }
  }

  public struct Participant: Equatable, Identifiable {
    public let id: String
    let name: String

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

  public let id: UUID
  let parentId: UUID?
  let title: String
  let subtitle: String
  let iconType: ActivityImageType
  public let isStrikethrough: Bool
  let displayedIcons: [Icon]
  let participants: [Participant]

  public var isSubtask: Bool { parentId != nil }
}

public enum DayActivityItemIconRules {
  case none
  case data(Data?)
  case iconId
}

extension DayActivityItem {
  public init(
    activityType: ActivityType,
    iconRules: DayActivityItemIconRules = .iconId,
    parentId: UUID? = nil
  ) {
    let isDueDateSet = activityType.dueDaysCount != nil && activityType.dueDaysCount ?? .zero > .zero
    let showHourglass = activityType.dueDate != nil || isDueDateSet
    let iconType: ActivityImageType
    switch iconRules {
    case .none:
      iconType = .empty
    case .data(let data):
      if let data {
        iconType = .data(data)
      } else {
        iconType = .placeholder
      }
    case .iconId:
      iconType = .iconId(activityType.iconId)
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
        activityType.isFrequentEnabled ? .repeat : nil
      ].compactMap { $0 },
      participants: activityType.participants.prefix(5).compactMap {
        guard $0.isShared else { return nil }
        return Participant(id: $0.id, name: $0.name)
      }
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
