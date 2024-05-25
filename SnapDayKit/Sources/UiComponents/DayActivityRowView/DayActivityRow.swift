import SwiftUI
import Models

public struct DayActivityRow: View, DurationFormatting {

  private let activity: ActivityType
  private let trailingIcon: TrailingIcon

  public init(
    activity: ActivityType,
    trailingIcon: TrailingIcon
  ) {
    self.activity = activity
    self.trailingIcon = trailingIcon
  }

  public var body: some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: activity.icon?.data,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: 2.0) {
        Text(activity.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
          .strikethrough(activity.isDone, color: .sectionText)
        subtitleView
      }
      Spacer()
      view(for: trailingIcon)
    }
    .padding(.all, 10.0)
  }

  @ViewBuilder
  private var subtitleView: some View {
    HStack(spacing: 5.0) {
      if let overview = activity.overview, !overview.isEmpty {
        Text(overview)
          .font(.system(size: 12.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.sectionText)
          .strikethrough(activity.isDone, color: .sectionText)
      }

      if let textDuration = duration(for: activity.duration) {
        if activity.overview != nil && activity.overview?.isEmpty == false {
          Text("-")
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.sectionText)
        }

        Text(textDuration)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
          .strikethrough(activity.isDone, color: .sectionText)
      }
    }
  }

  func view(for trailingIcon: TrailingIcon) -> AnyView {
    switch trailingIcon {
    case .none:
      AnyView(
        EmptyView()
      )
    case .more:
      AnyView(
        Image(systemName: "ellipsis")
          .foregroundStyle(Color.sectionText)
          .imageScale(.medium)
      )
    }
  }
}
