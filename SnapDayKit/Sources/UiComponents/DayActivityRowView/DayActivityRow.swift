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
          .lineLimit(1)
          .foregroundStyle(Color.sectionText)
          .strikethrough(isStrikethrough, color: .sectionText)
        subtitleView
      }
      Spacer(minLength: 5.0)
      HStack(spacing: .zero) {
        dueDateIconIfNeeded
        reminderIconIfNeeded
        view(for: trailingIcon)
          .contentShape(Rectangle())
          .onTapGesture {
            trailingViewTapped?()
          }
      }
    }
    .padding(
      EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 5.0)
    )
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
      prepareIcon("bell")
    }
  }

  @ViewBuilder
  private var dueDateIconIfNeeded: some View {
    if activity.dueDate != nil {
      prepareIcon("hourglass")
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
        prepareIcon("ellipsis")
      )
    }
  }

  private func prepareIcon(_ name: String) -> some View {
    Image(systemName: name)
      .resizable()
      .scaledToFit()
      .frame(width: 15.0, height: 15.0)
      .foregroundStyle(Color.sectionText)
      .imageScale(.medium)
      .padding(.all, 5.0)
  }
}
