import SwiftUI
import Models

public struct DayActivityRow: View {

  public enum Size {
    case small
    case medium
  }

  private let activityItem: DayActivityItem
  private let size: Size
  private let trailingIcon: TrailingIcon

  private var imageSize: (size: CGFloat, cornerRadius: CGFloat) {
    switch size {
    case .small:
      (20.0, 10.0)
    case .medium:
      (30.0, 15.0)
    }
  }

  private var fontSize: (titleSize: CGFloat, subtitleSize: CGFloat) {
    switch size {
    case .small:
      (12.0, 10.0)
    case .medium:
      (14.0, 12.0)
    }
  }

  private var trailingSpacing: Double {
    switch size {
    case .small:
      5.0
    case .medium:
      10.0
    }
  }

  private var padding: EdgeInsets {
    switch size {
    case .small:
      return EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
    case .medium:
      guard activityItem.iconType != .empty else {
        return EdgeInsets(top: 15.0, leading: 10.0, bottom: 15.0, trailing: 10.0)
      }
      return EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
    }
  }

  public init(
    activityItem: DayActivityItem,
    size: Size = .medium,
    trailingIcon: TrailingIcon = .none
  ) {
    self.activityItem = activityItem
    self.size = size
    self.trailingIcon = trailingIcon
  }

  public var body: some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        type: activityItem.iconType,
        size: imageSize.size,
        cornerRadius: imageSize.cornerRadius
      )
      VStack(alignment: .leading, spacing: 2.0) {
        titleView
        switch size {
        case .small:
          EmptyView()
        case .medium:
          subtitleView
        }
      }
      Spacer(minLength: 5.0)
      HStack(spacing: trailingSpacing) {
        VStack(alignment: .trailing, spacing: 5.0) {
          HStack(spacing: 5.0) {
            ForEach(activityItem.displayedIcons, content: dayActivityItem)
            HStack(spacing: -5.0) {
              ForEach(activityItem.participants, content: participantItem)
            }
          }
        }
        view(for: trailingIcon)
      }
      .padding(.trailing, 5.0)
    }
    .padding(padding)
  }

  private var titleView: some View {
    Text(activityItem.title)
      .font(.system(size: fontSize.titleSize, weight: .medium))
      .lineLimit(1)
      .foregroundStyle(Color.sectionText)
      .strikethrough(activityItem.isStrikethrough, color: .sectionText)
  }

  @ViewBuilder
  private var subtitleView: some View {
    if !activityItem.subtitle.isEmpty {
      Text(activityItem.subtitle)
        .font(.system(size: fontSize.subtitleSize, weight: .regular))
        .lineLimit(1)
        .foregroundStyle(Color.sectionText)
        .strikethrough(activityItem.isStrikethrough, color: .sectionText)
    }
  }

  private func dayActivityItem(icon: DayActivityItem.Icon) -> some View {
    Image(systemName: icon.rawValue)
      .iconable(color: Color.sectionText)
  }

  private func view(for trailingIcon: TrailingIcon) -> AnyView {
    switch trailingIcon {
    case .none:
      AnyView(EmptyView())
    case .customView(let view):
      AnyView(view)
    }
  }

  private func participantItem(_ participant: DayActivityItem.Participant) -> some View {
    Text(participant.initials)
      .font(.system(size: 15.0 / 2.0, weight: .bold))
      .foregroundColor(participant.backgroundColor.isLight() ? .sectionText : .pureWhite)
      .frame(width: 15.0, height: 15.0)
      .background(Circle().fill(participant.backgroundColor.color))
  }
}
