import SwiftUI
import Models

public struct DayActivityRow: View, DurationFormatting {

  private let activity: ActivityType
  private let shouldIgnoreDone: Bool
  private let trailingIcon: TrailingIcon
  private let trailingViewTapped: (() -> Void)?

  private var isStrikethrough: Bool {
    activity.isDone && !shouldIgnoreDone
  }

  public init(
    activity: ActivityType,
    shouldIgnoreDone: Bool = false,
    trailingIcon: TrailingIcon = .none,
    trailingViewTapped: (() -> Void)? = nil
  ) {
    self.activity = activity
    self.shouldIgnoreDone = shouldIgnoreDone
    self.trailingIcon = trailingIcon
    self.trailingViewTapped = trailingViewTapped
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
          .strikethrough(isStrikethrough, color: .sectionText)
        subtitleView
      }
      Spacer()
      HStack(spacing: 10.0) {
        reminderIconIfNeeded
        view(for: trailingIcon)
          .onTapGesture {
            trailingViewTapped?()
          }
      }
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
          .strikethrough(isStrikethrough, color: .sectionText)
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
          .strikethrough(isStrikethrough, color: .sectionText)
      }
    }
  }

  @ViewBuilder
  private var reminderIconIfNeeded: some View {
    if activity.reminderDate != nil {
      Image(systemName: "bell")
        .resizable()
        .scaledToFill()
        .fontWeight(.light)
        .frame(width: 15.0, height: 15.0)
        .foregroundStyle(Color.sectionText)
    }
  }

  private func view(for trailingIcon: TrailingIcon) -> AnyView {
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
    case .edit:
      AnyView(
        Image(systemName: "square.and.pencil")
          .foregroundStyle(Color.sectionText)
          .imageScale(.medium)
      )
    }
  }
}
