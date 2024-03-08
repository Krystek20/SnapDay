import SwiftUI
import Resources
import Models

public struct DayView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let completedActivities: CompletedActivities
  private let dayViewShowButtonState: DayViewShowButtonState
  private let activityTapped: (DayActivity) -> Void
  private let editTapped: (DayActivity) -> Void
  private let removeTapped: (DayActivity) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    completedActivities: CompletedActivities,
    dayViewShowButtonState: DayViewShowButtonState,
    activityTapped: @escaping (DayActivity) -> Void,
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.completedActivities = completedActivities
    self.dayViewShowButtonState = dayViewShowButtonState
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(activities, content: menuActivityView)
      doneRowViewIfNeeded()
      showOrHideDoneActivitiesViewIfNeeded()
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
      VStack(spacing: .zero) {
        dayActivityView(dayActivity)
        Divider()
      }
    }
  }

  @ViewBuilder
  private func doneRowViewIfNeeded() -> some View {
    if !activities.isEmpty {
      HStack(spacing: 10.0) {
        CircularProgressView(
          progress: completedActivities.percent,
          showPercent: false,
          lineWidth: 4.0
        )
        .frame(width: 20.0, height: 20.0)
        Text("Completed activities", bundle: .module)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.slateHaze)
        Spacer()
        Text("\(completedActivities.doneCount) / \(completedActivities.totalCount)", bundle: .module)
          .font(.system(size: 12.0, weight: .medium))
          .foregroundStyle(Color.slateHaze)
      }
      .padding(.all, 14.0)
      .background(Color.etherealLavender)
    }
  }

  @ViewBuilder
  private func showOrHideDoneActivitiesViewIfNeeded() -> some View {
    switch dayViewShowButtonState {
    case .show:
      showOrHideDoneActivitiesView(
        title: String(localized: "Show completed", bundle: .module),
        icon: Image(systemName: "arrow.up.left.and.arrow.down.right"),
        actionHandler: showCompletedTapped
      )
    case .hide:
      showOrHideDoneActivitiesView(
        title: String(localized: "Hide completed", bundle: .module),
        icon: Image(systemName: "arrow.down.right.and.arrow.up.left"),
        actionHandler: hideCompletedTapped
      )
    case .none:
      EmptyView()
    }
  }

  private func showOrHideDoneActivitiesView(
    title: String,
    icon: Image,
    actionHandler: @escaping () -> Void
  ) -> some View {
    VStack(spacing: .zero) {
      Button(
        action: actionHandler,
        label: {
          HStack(spacing: 12.5) {
            icon
              .resizable()
              .foregroundStyle(Color.lavenderBliss)
              .frame(width: 15.0, height: 15.0)
              .padding(.leading, 2.5)
            Text(title)
              .font(.system(size: 14.0, weight: .medium))
              .foregroundStyle(Color.lavenderBliss)
            Spacer()
          }
          .padding(.all, 14.0)
        }
      )
      Divider()
    }
  }

  private func dayActivityView(_ dayActivity: DayActivity) -> some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: dayActivity.activity.image,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: 2.0) {
        Text(dayActivity.activity.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.slateHaze)
          .strikethrough(dayActivity.isDone, color: .slateHaze)
        if let textDuration = duration(for: dayActivity) {
          Text(textDuration)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.slateHaze)
            .strikethrough(dayActivity.isDone, color: .slateHaze)
        }
      }
      Spacer()
      Image(systemName: "ellipsis")
        .foregroundStyle(Color.slateHaze)
        .imageScale(.medium)
    }
    .padding(.all, 10.0)
  }

  // MARK: - Helpers

  private func duration(for dayActivity: DayActivity) -> String? {
    guard dayActivity.duration > .zero else { return nil }
    let minutes = dayActivity.duration % 60
    let hours = dayActivity.duration / 60
    return String(localized: "\(hours)h \(minutes)min", bundle: .module)
  }
}
