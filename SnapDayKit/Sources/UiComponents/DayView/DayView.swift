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
  private let activityTaskTapped: (DayActivity, DayActivityTask) -> Void
  private let editTaskTapped: (DayActivity, DayActivityTask) -> Void
  private let removeTaskTapped: (DayActivity, DayActivityTask) -> Void
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
    activityTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    editTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    removeTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
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
    self.activityTaskTapped = activityTaskTapped
    self.editTaskTapped = editTaskTapped
    self.removeTaskTapped = removeTaskTapped
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(activities) { dayActivity in
        VStack(spacing: .zero) {
          menuActivityView(dayActivity)
          Divider()
            .padding(.leading, dayActivity.dayActivityTasks.isEmpty ? .zero : 20.0)
        }

        ForEach(tasks(for: dayActivity)) { activityTask in
          VStack(spacing: .zero) {
            menuActivityTaskView(dayActivity, activityTask)
              .padding(.leading, 10.0)
            Divider()
              .padding(.leading, dayActivity.dayActivityTasks.last?.id == activityTask.id ? .zero : 20.0)
          }
        }
      }
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
      dayActivityView(dayActivity)
    }
  }

  @ViewBuilder
  private func doneRowViewIfNeeded() -> some View {
    if !activities.isEmpty {
      HStack(spacing: 10.0) {
        CircularProgressView(
          progress: completedActivities.percent,
          lineWidth: 4.0
        )
        .frame(width: 20.0, height: 20.0)
        Text("Completed activities", bundle: .module)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.standardText)
        Spacer()
        Text("\(completedActivities.doneCount) / \(completedActivities.totalCount)", bundle: .module)
          .font(.system(size: 12.0, weight: .semibold))
          .foregroundStyle(Color.standardText)
      }
      .padding(.all, 14.0)
      .background(Color.selection)
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
              .foregroundStyle(Color.actionBlue)
              .frame(width: 15.0, height: 15.0)
              .padding(.leading, 2.5)
            Text(title)
              .font(.system(size: 14.0, weight: .medium))
              .foregroundStyle(Color.actionBlue)
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
        data: dayActivity.icon?.data,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: 2.0) {
        Text(dayActivity.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivity.isDone, color: .sectionText)
        subtitleView(for: dayActivity)
      }
      Spacer()
      Image(systemName: "ellipsis")
        .foregroundStyle(Color.sectionText)
        .imageScale(.medium)
    }
    .padding(.all, 10.0)
  }

  @ViewBuilder
  private func subtitleView(for dayActivity: DayActivity) -> some View {
    HStack(spacing: 5.0) {
      if let overview = dayActivity.overview, !overview.isEmpty {
        Text(overview)
          .font(.system(size: 12.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivity.isDone, color: .sectionText)
      }

      if let textDuration = duration(for: dayActivity.totalDuration) {
        if dayActivity.overview != nil && dayActivity.overview?.isEmpty == false {
          Text("-")
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.sectionText)
        }

        Text(textDuration)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivity.isDone, color: .sectionText)
      }
    }
  }

  private func menuActivityTaskView(_ dayActivity: DayActivity, _ dayActivityTask: DayActivityTask) -> some View {
    Menu {
      Button(
        action: {
          activityTaskTapped(dayActivity, dayActivityTask)
        },
        label: {
          if dayActivityTask.isDone {
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
          editTaskTapped(dayActivity, dayActivityTask)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          removeTaskTapped(dayActivity, dayActivityTask)
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    } label: {
      dayActivityTaskView(dayActivityTask)
    }
  }

  private func dayActivityTaskView(_ dayActivityTask: DayActivityTask) -> some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: dayActivityTask.icon?.data,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: 2.0) {
        Text(dayActivityTask.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.isDone, color: .sectionText)
        subtitleView(for: dayActivityTask)
      }
      Spacer()
      Image(systemName: "ellipsis")
        .foregroundStyle(Color.sectionText)
        .imageScale(.medium)
    }
    .padding(.all, 10.0)
  }

  @ViewBuilder
  private func subtitleView(for dayActivityTask: DayActivityTask) -> some View {
    HStack(spacing: 5.0) {
      if let overview = dayActivityTask.overview, !overview.isEmpty {
        Text(overview)
          .font(.system(size: 12.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.isDone, color: .sectionText)
      }

      if let textDuration = duration(for: dayActivityTask.duration) {
        if dayActivityTask.overview != nil && dayActivityTask.overview?.isEmpty == false {
          Text("-")
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.sectionText)
        }

        Text(textDuration)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.isDone, color: .sectionText)
      }
    }
  }

  // MARK: - Helpers

  private func duration(for duration: Int) -> String? {
    guard duration > .zero else { return nil }
    let minutes = duration % 60
    let hours = duration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }

  private func tasks(for dayActivity: DayActivity) -> [DayActivityTask] {
    switch dayViewShowButtonState {
    case .show:
      dayActivity.toDoTasks
    case .hide, .none:
      dayActivity.dayActivityTasks
    }
  }
}
