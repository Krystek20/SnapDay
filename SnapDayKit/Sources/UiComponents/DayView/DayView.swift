import SwiftUI
import Resources
import Models

public struct DayView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let completedActivities: CompletedActivities
  private let dayViewShowButtonState: DayViewShowButtonState
  private let dayViewOption: DayViewOption
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    completedActivities: CompletedActivities,
    dayViewShowButtonState: DayViewShowButtonState,
    dayViewOption: DayViewOption,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.completedActivities = completedActivities
    self.dayViewShowButtonState = dayViewShowButtonState
    self.dayViewOption = dayViewOption
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(activities) { dayActivity in
        switch dayViewOption {
        case .all(let dayViewAllActions):
          menuActivityView(dayActivity, dayViewAllActions)
        }
        divider(addPadding: !dayActivity.dayActivityTasks.isEmpty)

        ForEach(tasks(for: dayActivity)) { activityTask in
          switch dayViewOption {
          case .all(let dayViewAllActions):
            menuActivityTaskView(activityTask, dayViewAllActions)
              .padding(.leading, 10.0)
          }
          divider(addPadding: dayActivity.dayActivityTasks.last?.id != activityTask.id)
        }
      }
      doneRowViewIfNeeded()
      showOrHideDoneActivitiesViewIfNeeded()
    }
  }

  private func menuActivityView(
    _ dayActivity: DayActivity,
    _ dayViewAllActions: DayViewAllActions
  ) -> some View {
    Menu {
      Button(
        action: {
          dayViewAllActions.activityTapped(dayActivity)
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
          dayViewAllActions.editTapped(dayActivity)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          dayViewAllActions.addNewActivityTask(dayActivity)
        },
        label: {
          Text("Add task", bundle: .module)
          Image(systemName: "plus.circle")
        }
      )
      Button(
        action: {
          dayViewAllActions.removeTapped(dayActivity)
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

  private func menuActivityTaskView(
    _ dayActivityTask: DayActivityTask,
    _ dayViewAllActions: DayViewAllActions
  ) -> some View {
    Menu {
      Button(
        action: {
          dayViewAllActions.activityTaskTapped(dayActivityTask)
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
          dayViewAllActions.editTaskTapped(dayActivityTask)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          dayViewAllActions.removeTaskTapped(dayActivityTask)
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
