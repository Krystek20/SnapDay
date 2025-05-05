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

  @State private var draggedActivity: DayActivity?

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
        menuActivityView(dayActivity, newForms: newForms)
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
            type: .placeholder,
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
        .padding(EdgeInsets(top: 15.0, leading: 10.0, bottom: 15.0, trailing: 10.0))
      }
      .onSubmit {
        newForms.newActivityAction(.dayActivityTask(.submitted))
      }
      .padding(.leading, 10.0)
      divider(addPadding: !dayActivity.dayActivityTasks.isEmpty)
    }
  }

  private func menuActivityView(_ dayActivity: DayActivity, newForms: NewForms?) -> some View {
    VStack(spacing: .zero) {
      DayActivityRow(
        activityItem: DayActivityItem(activityType: dayActivity),
        trailingIcon: .customView(
          trailingView(for: dayActivity)
        )
      )

      if let newForms {
        newActivityTaskFormIfNeeded(newForms: newForms, dayActivity: dayActivity)
      }

      ForEach(tasks(for: dayActivity)) { activityTask in
        menuActivityTaskView(activityTask, isInvitation: dayActivity.isInvitation)
          .padding(.leading, 10.0)
        divider(addPadding: dayActivity.dayActivityTasks.last?.id != activityTask.id)
      }
    }
    .contentShape(Rectangle())
    .drag(if: !dayActivity.isDone, data: {
      draggedActivity = dayActivity
      return NSItemProvider()
    })
    .onDrop(
      of: [.text],
      delegate: ItemDropDelegate(
        destinationItem: dayActivity,
        draggedItem: $draggedActivity,
        moveAction: { draggedActivity in
          dayActivityAction(.dayActivity(.reorder(.perform(destination: dayActivity)), draggedActivity))
        },
        performDrop: {
          dayActivityAction(.dayActivity(.reorder(.drop), dayActivity))
        }
      )
    )
  }

  private func trailingView(for dayActivity: DayActivity) -> some View {
    dayActivity.isInvitation
    ? AnyView(invitation(for: dayActivity))
    : AnyView(dayActivityMenu(for: dayActivity))
  }

  private func invitation(for dayActivity: DayActivity) -> some View {
    HStack(spacing: 10.0) {
      Button {
        dayActivityAction(.dayActivity(.acceptInvitation, dayActivity))
      } label: {
        Image(systemName: "checkmark.circle.fill")
          .iconable(color: Color.greenSuccess)
      }
      Button {
        dayActivityAction(.dayActivity(.discardInvitation, dayActivity))
      } label: {
        Image(systemName: "xmark.circle.fill")
          .iconable(color: Color.alertText)
      }
    }
  }

  private func dayActivityMenu(for dayActivity: DayActivity) -> some View {
    TrailingIcon.moreIcon
      .overlay {
        dayActivityMenuView(dayActivity: dayActivity)
      }
  }

  private func dayActivityMenuView(dayActivity: DayActivity) -> some View {
    Menu {
      dayActivity.isDone
      ? menuItem(for: .deselect, dayActivity: dayActivity, actionType: .tapped)
      : menuItem(for: .select, dayActivity: dayActivity, actionType: .tapped)

      menuItem(for: .edit, dayActivity: dayActivity, actionType: .edit)
      menuItem(for: .addTask, dayActivity: dayActivity, actionType: .addActivityTask)

      dayActivity.important
      ? menuItem(for: .imortantUnmark, dayActivity: dayActivity, actionType: .unmarkImportant)
      : menuItem(for: .importantMark, dayActivity: dayActivity, actionType: .markImportant)

      if dayActivity.activity == nil {
        menuItem(for: .save, dayActivity: dayActivity, actionType: .save)
      }

      menuItem(for: .move, dayActivity: dayActivity, actionType: .move)
      menuItem(for: .copy, dayActivity: dayActivity, actionType: .copy)

      if let share = dayActivity.share {
        if share.isOwner {
          collaborateMenuItem(participants: share.availableParticipants, dayActivity: dayActivity)
        } else {
          menuItem(for: .stopCollaboration, dayActivity: dayActivity, actionType: .stopCollaboration)
        }
      }

      menuItem(for: .remove, dayActivity: dayActivity, actionType: .remove)
    } label: {
      Color.clear
        .frame(width: 30.0, height: 30.0)
    }
  }

  private func collaborateMenuItem(participants: [DayActivityParticipant], dayActivity: DayActivity) -> some View {
    Menu {
      ForEach(participants) { participant in
        Button(
          action: {
            participant.isShared
            ? dayActivityAction(.dayActivity(.removeParticipant(participant), dayActivity))
            : dayActivityAction(.dayActivity(.addParticipant(participant), dayActivity))
          },
          label: {
            Text(participant.name)
            participant.isShared
            ? Image(systemName: "person.badge.minus")
            : Image(systemName: "person.badge.plus")
          }
        )
      }
    } label: {
      dayActivity.isShared
      ? Text(DayActivityMenuItem.collaborateMarked.title)
      : Text(DayActivityMenuItem.collaborateUnmarked.title)
      dayActivity.isShared
      ? Image(systemName: DayActivityMenuItem.collaborateMarked.imageName)
      : Image(systemName: DayActivityMenuItem.collaborateUnmarked.imageName)
    }
  }

  private func menuItem(
    for menuItem: DayActivityMenuItem,
    dayActivity: DayActivity,
    actionType: DayActivityActionType.DayActivityAction
  ) -> some View {
    Button(
      action: {
        dayActivityAction(.dayActivity(actionType, dayActivity))
      },
      label: {
        Text(menuItem.title)
        Image(systemName: menuItem.imageName)
      }
    )
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
              .iconable(color: Color.actionBlue)
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

  private func menuActivityTaskView(_ dayActivityTask: DayActivityTask, isInvitation: Bool) -> some View {
    DayActivityRow(
      activityItem: DayActivityItem(activityType: dayActivityTask, iconRules: .none),
      trailingIcon: isInvitation
      ? .none
      : .customView(
        TrailingIcon.moreIcon
          .overlay {
            dayActivityTaskMenuView(dayActivityTask: dayActivityTask)
          }
      )
    )
  }

  private func dayActivityTaskMenuView(dayActivityTask: DayActivityTask) -> some View {
    Menu {
      dayActivityTask.isDone
      ? taskMenuItem(for: .deselect, dayActivityTask: dayActivityTask)
      : taskMenuItem(for: .select, dayActivityTask: dayActivityTask)
      taskMenuItem(for: .edit, dayActivityTask: dayActivityTask)
      taskMenuItem(for: .remove, dayActivityTask: dayActivityTask)
    } label: {
      Color.clear
        .frame(width: 30.0, height: 30.0)
    }
  }

  private func taskMenuItem(for menuItem: DayActivityTaskMenuItem, dayActivityTask: DayActivityTask) -> some View {
    Button(
      action: {
        dayActivityAction(.dayActivityTask(menuItem.dayActivityTaskAction, dayActivityTask))
      },
      label: {
        Text(menuItem.title)
        Image(systemName: menuItem.imageName)
      }
    )
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
