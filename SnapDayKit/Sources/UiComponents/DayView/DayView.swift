import SwiftUI
import Resources
import Models

public struct DayView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let activityTapped: (DayActivity) -> Void
  private let editTapped: (DayActivity) -> Void
  private let removeTapped: (DayActivity) -> Void

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    activityTapped: @escaping (DayActivity) -> Void, 
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: 5.0) {
      ForEach(activities, content: planView)
    }
  }

  private func planView(_ dayActivity: DayActivity) -> some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: dayActivity.activity.image,
        size: 20.0,
        cornerRadius: 10.0
      )
      Text(dayActivity.activity.name)
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
        .strikethrough(dayActivity.isDone, color: Colors.slateHaze.swiftUIColor)
      if let textDuration = duration(for: dayActivity) {
        Text(textDuration)
          .font(Fonts.Quicksand.regular.swiftUIFont(size: 12.0))
          .foregroundStyle(Colors.slateHaze.swiftUIColor)
          .strikethrough(dayActivity.isDone, color: Colors.slateHaze.swiftUIColor)
      }
      Spacer()
      Image(systemName: dayActivity.isDone ? "checkmark.square.fill" : "square")
        .foregroundStyle(dayActivity.isDone ? Colors.lavenderBliss.swiftUIColor : Colors.slateHaze.swiftUIColor)
        .imageScale(.medium)
    }
    .formBackgroundModifier
    .contextMenu {
      Button(
        action: {
          editTapped(dayActivity)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )

      Button(
        action: {
          removeTapped(dayActivity)
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    }
    .onTapGesture {
      activityTapped(dayActivity)
    }
  }

  // MARK: - Helpers

  private func duration(for dayActivity: DayActivity) -> String? {
    guard dayActivity.duration > .zero else { return nil }
    let minutes = dayActivity.duration % 60
    let hours = dayActivity.duration / 60
    return String(localized: "\(hours)h \(minutes)min", bundle: .module)
  }
}
