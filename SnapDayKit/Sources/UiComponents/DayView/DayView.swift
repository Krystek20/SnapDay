import SwiftUI
import Resources
import Models

public struct DayView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let activityListOption: ActivityListOption
  private let activityTapped: (DayActivity) -> Void
  private let editTapped: (DayActivity) -> Void
  private let removeTapped: (DayActivity) -> Void

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    activityListOption: ActivityListOption,
    activityTapped: @escaping (DayActivity) -> Void,
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.activityListOption = activityListOption
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: 5.0) {
      ForEach(activities, content: menuActivityView)
      doneRowViewIfCollapsed()
    }
  }

  private func menuActivityView(_ dayActivity: DayActivity) -> some View {
    Menu {
      Button(
        action: {
          activityTapped(dayActivity)
        },
        label: {
          if dayActivity.isDone {
            Text("Deselect", bundle: .module)
            Image(systemName: "x.circle")
          } else {
            Text("Select", bundle: .module)
            Image(systemName: "checkmark.circle")
          }
        }
      )
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
    } label: {
      dayActivityView(dayActivity)
    }
  }

  @ViewBuilder
  private func doneRowViewIfCollapsed() -> some View {
    if case .collapsed(let doneCount, let totalCount, let progress) = activityListOption {
      HStack(spacing: 10.0) {
        CircularProgressView(
          progress: progress,
          showPercent: false,
          lineWidth: 4.0
        )
        .frame(width: 20.0, height: 20.0)
        Text("Completed activities", bundle: .module)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
          .foregroundStyle(Colors.slateHaze.swiftUIColor)
        Spacer()
        Text("\(doneCount) / \(totalCount)", bundle: .module)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
          .foregroundStyle(Colors.slateHaze.swiftUIColor)
      }
      .formBackgroundModifier(color: Colors.etherealLavender.swiftUIColor)
    }
  }

  private func dayActivityView(_ dayActivity: DayActivity) -> some View {
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
    .formBackgroundModifier()
  }

  // MARK: - Helpers

  private func duration(for dayActivity: DayActivity) -> String? {
    guard dayActivity.duration > .zero else { return nil }
    let minutes = dayActivity.duration % 60
    let hours = dayActivity.duration / 60
    return String(localized: "\(hours)h \(minutes)min", bundle: .module)
  }
}
