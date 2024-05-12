import SwiftUI
import Models

public struct ActivitySummaryRow: View {

  public enum ActivityType {
    case activity(Activity)
    case dayActivity(DayActivity)
  }

  public enum DurationType {
    case fromActivity
    case custom(Int)
  }

  // MARK: - Properties

  private let activityType: ActivityType
  private let durationType: DurationType

  private var duration: Int {
    switch durationType {
    case .fromActivity:
      switch activityType {
      case .activity(let activity):
        activity.defaultDuration ?? .zero
      case .dayActivity(let dayActivity):
        dayActivity.totalDuration
      }
    case .custom(let duration):
      duration
    }
  }

  private var iconData: Data? {
    switch activityType {
    case .activity(let activity):
      activity.icon?.data
    case .dayActivity(let dayActivity):
      dayActivity.icon?.data
    }
  }

  private var name: String {
    switch activityType {
    case .activity(let activity):
      activity.name
    case .dayActivity(let dayActivity):
      dayActivity.name
    }
  }

  // MARK: - Initialization

  public init(activityType: ActivityType, durationType: DurationType) {
    self.activityType = activityType
    self.durationType = durationType
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: iconData,
        size: 30.0,
        cornerRadius: 15.0
      )
      Text(name)
        .font(.system(size: 14.0, weight: .medium))
        .multilineTextAlignment(.leading)
        .foregroundStyle(Color.sectionText)
      Spacer()
      if duration > .zero {
        DurationLabel(duration: duration)
      }
    }
  }
}
