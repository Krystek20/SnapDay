import SwiftUI
import Resources
import Models

public struct DayView: View {

  public struct NewForms {
    var newActivityBinding: Binding<DayNewActivity>
    var newActivityTaskBinding: Binding<DayNewActivityTask>
    var focus: FocusState<DayNewField?>.Binding
    let newActivityAction: (DayNewActivityAction) -> Void

    var newActivity: DayNewActivity {
      newActivityBinding.wrappedValue
    }

    var newActivityTask: DayNewActivityTask {
      newActivityTaskBinding.wrappedValue
    }

    public init(
      newActivity: Binding<DayNewActivity>,
      newActivityTask: Binding<DayNewActivityTask>,
      focus: FocusState<DayNewField?>.Binding,
      newActivityAction: @escaping (DayNewActivityAction) -> Void
    ) {
      self.newActivityBinding = newActivity
      self.newActivityTaskBinding = newActivityTask
      self.focus = focus
      self.newActivityAction = newActivityAction
    }
  }

  // MARK: - Properties

  private let activities: [DayActivity]
  private let newForms: NewForms?
  private let completedActivities: CompletedActivities
  private let dayViewShowButtonState: DayViewShowButtonState
  private let dayActivityAction: (DayActivityActionType) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    newForms: NewForms? = nil,
    activities: [DayActivity],
    completedActivities: CompletedActivities,
    dayViewShowButtonState: DayViewShowButtonState,
    dayActivityAction: @escaping (DayActivityActionType) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self.newForms = newForms
    self.activities = activities
    self.completedActivities = completedActivities
    self.dayViewShowButtonState = dayViewShowButtonState
    self.dayActivityAction = dayActivityAction
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: .zero) {
      if let newForms {
        newActivityFormIfNeeded(newForm: newForms)
      }
      ForEach(activities) { dayActivity in
        menuActivityView(dayActivity)

        if let newForms {
          newActivityTaskFormIfNeeded(newForms: newForms, dayActivity: dayActivity)
        }

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

  @ViewBuilder
  private func newActivityFormIfNeeded(newForm: NewForms) -> some View {
    if newForm.newActivity.isFormVisible {
      VStack(spacing: .zero) {
        HStack(spacing: 5.0) {
          ActivityImageView(
            data: nil,
            size: 30.0,
            cornerRadius: 15.0
          )
          TextField("", text: newForm.newActivityBinding.name)
            .font(.system(size: 14.0, weight: .medium))
            .foregroundStyle(Color.sectionText)
            .submitLabel(.done)
            .focused(newForm.focus, equals: .activityName)
          Spacer()
          if !newForm.newActivity.name.isEmpty {
            Button(String(localized: "Cancel", bundle: .module), action: {
              newForm.newActivityAction(.dayActivity(.cancelled))
            })
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.actionBlue)
          }
        }
        .padding(.all, 10.0)
        if !activities.isEmpty {
          divider(addPadding: false)
        }
      }
      .onSubmit {
        newForm.newActivityAction(.dayActivity(.submitted))
      }
    }
  }

  @ViewBuilder
  private func newActivityTaskFormIfNeeded(newForms: NewForms, dayActivity: DayActivity) -> some View {
    let showNewTaskForm = newForms.newActivityTask.activityId == dayActivity.id && newForms.newActivityTask.isFormVisible
    divider(addPadding: showNewTaskForm || !dayActivity.dayActivityTasks.isEmpty)
    if showNewTaskForm {
      VStack(spacing: .zero) {
        HStack(spacing: 5.0) {
          ActivityImageView(
            data: nil,
            size: 30.0,
            cornerRadius: 15.0
          )
          TextField("", text: newForms.newActivityTaskBinding.name)
            .font(.system(size: 14.0, weight: .medium))
            .foregroundStyle(Color.sectionText)
            .submitLabel(.done)
            .focused(newForms.focus, equals: .taskName(identifier: newForms.newActivityTask.activityId?.uuidString ?? ""))
          Spacer()
          if !newForms.newActivityTask.name.isEmpty {
            Button(String(localized: "Cancel", bundle: .module), action: {
              newForms.newActivityAction(.dayActivityTask(.cancelled))
            })
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.actionBlue)
          }
        }
        .padding(.all, 10.0)
      }
      .onSubmit {
        newForms.newActivityAction(.dayActivityTask(.submitted))
      }
      .padding(.leading, 10.0)
      divider(addPadding: !dayActivity.dayActivityTasks.isEmpty)
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
      if dayActivity.activity == nil {
        Button(
          action: {
            dayActivityAction(.dayActivity(.save, dayActivity))
          },
          label: {
            Text("Save", bundle: .module)
            Image(systemName: "square.and.arrow.down")
          }
        )
      }
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
        activityItem: DayActivityItem(activityType: dayActivity),
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
        activityItem: DayActivityItem(activityType: dayActivityTask),
        trailingIcon: .more
      )
    }
  }

  // MARK: - Helpers

  private func tasks(for dayActivity: DayActivity) -> [DayActivityTask] {
    switch dayViewShowButtonState {
    case .show:
      dayActivity.ordered(hideCompleted: true)
    case .hide, .none:
      dayActivity.ordered(hideCompleted: false)
    }
  }
}
