import SwiftUI
import Resources
import Models

public struct DayView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let completedActivities: CompletedActivities
  private let dayViewShowButtonState: DayViewShowButtonState
  private let dayActivityAction: (DayActivityActionType) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    completedActivities: CompletedActivities,
    dayViewShowButtonState: DayViewShowButtonState,
    dayActivityAction: @escaping (DayActivityActionType) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.completedActivities = completedActivities
    self.dayViewShowButtonState = dayViewShowButtonState
    self.dayActivityAction = dayActivityAction
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(activities) { dayActivity in
        menuActivityView(dayActivity)
        divider(addPadding: !dayActivity.dayActivityTasks.isEmpty)

        ForEach(tasks(for: dayActivity)) { activityTask in
          menuActivityTaskView(activityTask)
            .padding(.leading, 10.0)
          divider(addPadding: dayActivity.dayActivityTasks.last?.id != activityTask.id)
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
          dayActivityAction(.dayActivity(.tapped, dayActivity))
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
          dayActivityAction(.dayActivity(.edit, dayActivity))
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          dayActivityAction(.dayActivity(.addActivityTask, dayActivity))
        },
        label: {
          Text("Add task", bundle: .module)
          Image(systemName: "plus.circle")
        }
      )
      Button(
        action: {
          dayActivityAction(.dayActivity(.move, dayActivity))
        },
        label: {
          Text("Move", bundle: .module)
          Image(systemName: "arrow.left.and.right")
        }
      )
      Button(
        action: {
          dayActivityAction(.dayActivity(.copy, dayActivity))
        },
        label: {
          Text("Copy", bundle: .module)
          Image(systemName: "doc.on.doc")
        }
      )
      Button(
        action: {
          dayActivityAction(.dayActivity(.remove, dayActivity))
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    } label: {
      DayActivityRow(
        activity: dayActivity,
        trailingIcon: .more
      )
    }
  }

  private func divider(addPadding: Bool) -> some View {
    Divider()
      .padding(.leading, addPadding ? 20.0 : .zero)
  }

  @ViewBuilder
  private func doneRowViewIfNeeded() -> some View {
    if !activities.isEmpty {
      CompletedActivitiesView(completedActivities: completedActivities)
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
    }
  }

  private func menuActivityTaskView(_ dayActivityTask: DayActivityTask) -> some View {
    Menu {
      Button(
        action: {
          dayActivityAction(.dayActivityTask(.tapped, dayActivityTask))
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
          dayActivityAction(.dayActivityTask(.edit, dayActivityTask))
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          dayActivityAction(.dayActivityTask(.remove, dayActivityTask))
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    } label: {
      DayActivityRow(
        activity: dayActivityTask,
        trailingIcon: .more
      )
    }
  }

  // MARK: - Helpers

  private func tasks(for dayActivity: DayActivity) -> [DayActivityTask] {
    switch dayViewShowButtonState {
    case .show:
      dayActivity.toDoTasks
    case .hide, .none:
      dayActivity.dayActivityTasks
    }
  }
}
