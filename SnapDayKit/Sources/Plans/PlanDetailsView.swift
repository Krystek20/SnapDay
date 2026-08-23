import ComposableArchitecture
import Models
import Resources
import SwiftUI
import UiComponents
import Utilities

@MainActor
public struct PlanDetailsView: View {

  @Bindable private var store: StoreOf<PlanDetailsFeature>
  private let calendar = Calendar.autoupdatingCurrent.utcCalendar

  public init(store: StoreOf<PlanDetailsFeature>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        planHeader

        switch content.status {
        case .active:
          activeContent
        case .finished:
          finishedContent
        case .archived:
          archivedContent
        }
      }
      .padding(15.0)
    }
    .background(Color.background)
    .navigationTitle(Text("Plan details", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { managementToolbar }
    .task(id: store.plan.id) { await store.send(.view(.task)).finish() }
    .alert(
      String(localized: "Archive this plan?", bundle: .module),
      isPresented: archiveConfirmationBinding
    ) {
      Button(
        String(localized: "Archive plan", bundle: .module),
        role: .destructive,
        action: { store.send(.view(.archiveConfirmed)) }
      )
      Button(
        String(localized: "Cancel", bundle: .module),
        role: .cancel,
        action: { store.send(.view(.archiveCancelled)) }
      )
    } message: {
      Text("This plan will move to History. Its completed activities and progress will be kept.", bundle: .module)
    }
    .alert(
      String(localized: "Delete this plan?", bundle: .module),
      isPresented: deleteConfirmationBinding
    ) {
      Button(
        String(localized: "Delete plan", bundle: .module),
        role: .destructive,
        action: { store.send(.view(.deleteConfirmed)) }
      )
      Button(
        String(localized: "Cancel", bundle: .module),
        role: .cancel,
        action: { store.send(.view(.deleteCancelled)) }
      )
    } message: {
      Text("The plan and its progress will be deleted. Completed activities will remain in your history.", bundle: .module)
    }
    .alert(
      String(localized: "This plan can't be restored", bundle: .module),
      isPresented: restoreUnavailableBinding
    ) {
      Button(String(localized: "Create similar", bundle: .module)) {
        store.send(.view(.createSimilarButtonTapped))
      }
      Button(String(localized: "Cancel", bundle: .module), role: .cancel) {
        store.send(.view(.restoreUnavailableDismissed))
      }
    } message: {
      Text("Its date range has ended or its schedule is empty. Create a similar plan with a new schedule.", bundle: .module)
    }
    .alert(
      String(localized: "Plan couldn't be saved", bundle: .module),
      isPresented: saveErrorBinding
    ) {
      Button(String(localized: "OK", bundle: .module)) {
        store.send(.view(.saveErrorDismissed))
      }
    } message: {
      Text("Your changes are still open. Please try saving again.", bundle: .module)
    }
    .sheet(item: $store.scope(state: \.newPlan, action: \.newPlan)) { store in
      NewPlanView(store: store)
        .interactiveDismissDisabled()
    }
  }

  private var content: PlanDetailsContent {
    PlanDetailsContent(
      plan: store.plan,
      activities: store.activities,
      occurrences: store.occurrences,
      dayActivities: store.dayActivities,
      referenceDate: store.referenceDate ?? .now,
      calendar: calendar
    )
  }

  private var planHeader: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      statusPill

      Text(store.plan.name)
        .font(.system(size: 24.0, weight: .bold))
        .foregroundStyle(Color.primaryText)

      Text(dateRangeText)
        .font(.system(size: 13.0))
        .foregroundStyle(Color.secondaryText)

      HStack(alignment: .lastTextBaseline, spacing: 10.0) {
        Text(progressSummary)
          .font(.system(size: 13.0))
          .foregroundStyle(Color.secondaryText)

        Spacer(minLength: 10.0)

        Text(verbatim: "\(content.progress.percentComplete)%")
          .font(.system(size: 30.0, weight: .bold))
          .foregroundStyle(Color.primaryText)
      }

      DetailsProgressBar(value: content.progress.fractionComplete)
    }
    .padding(15.0)
    .background(Color.formBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14.0))
  }

  @ViewBuilder
  private var activeContent: some View {
    sectionTitle(
      String(localized: "Today", bundle: .module),
      trailing: (store.referenceDate ?? .now).formatted(template: "EEEE", calendar: calendar)
    )

    if content.todayActivities.isEmpty {
      restDayCard
    } else {
      todayCard
    }

    sectionTitle(String(localized: "This week", bundle: .module))
    scheduleCard(days: content.scheduledDays, showsState: true)
  }

  private var todayCard: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        Text(
          "\(content.completedTodayCount) of \(content.todayActivities.count) activities complete",
          bundle: .module
        )
          .font(.system(size: 17.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)

        Text("Complete today's activities from your Dashboard.", bundle: .module)
          .font(.system(size: 13.0))
          .foregroundStyle(Color.secondaryText)
      }

      ForEach(Array(content.todayActivities.enumerated()), id: \.element.id) { index, activity in
        if index > 0 { Divider() }
        activityRow(activity)
      }
    }
    .detailsCard()
  }

  private var restDayCard: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        Text("No activities planned today", bundle: .module)
          .font(.system(size: 17.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)

        Text("This plan has nothing scheduled today. Your daily list may still include other activities.", bundle: .module)
          .font(.system(size: 13.0))
          .foregroundStyle(Color.secondaryText)
      }

      if let nextDay = content.nextPlannedDay {
        Divider()

        VStack(alignment: .leading, spacing: 10.0) {
          Text("Next planned day", bundle: .module)
            .font(.system(size: 11.0, weight: .semibold))
            .foregroundStyle(Color.sectionText)

          Text(nextDay.title)
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)

          chipRow(nextDay.activities)
        }
      }
    }
    .detailsCard()
  }

  @ViewBuilder
  private var finishedContent: some View {
    activityBreakdownContent

    sectionTitle(String(localized: "Original schedule", bundle: .module))
    scheduleCard(days: content.scheduledDays, showsState: false)

    lifecycleButtons(for: .finished)
  }

  @ViewBuilder
  private var archivedContent: some View {
    sectionTitle(String(localized: "Status", bundle: .module))

    VStack(alignment: .leading, spacing: 5.0) {
      Text("This plan is not active", bundle: .module)
        .font(.system(size: 17.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)

      Text("It no longer generates activities. Its previous schedule and progress are kept for reference.", bundle: .module)
        .font(.system(size: 13.0))
        .foregroundStyle(Color.secondaryText)
    }
    .detailsCard()

    activityBreakdownContent

    sectionTitle(String(localized: "Previous schedule", bundle: .module))
    scheduleCard(days: content.scheduledDays, showsState: false)

    lifecycleButtons(for: .archived)
  }

  @ViewBuilder
  private var activityBreakdownContent: some View {
    sectionTitle(String(localized: "Activities", bundle: .module))

    if content.activityBreakdown.isEmpty {
      noActivitiesCard
    } else {
      activityBreakdownCard
    }
  }

  private var activityBreakdownCard: some View {
    VStack(alignment: .leading, spacing: 0.0) {
      ForEach(Array(content.activityBreakdown.enumerated()), id: \.element.id) { index, item in
        if index > 0 { Divider().padding(.vertical, 15.0) }
        HStack(spacing: 10.0) {
          Text(item.activity.name)
            .font(.system(size: 15.0, weight: .medium))
            .foregroundStyle(Color.primaryText)
          Spacer(minLength: 10.0)
          Text(verbatim: "\(item.completedCount) / \(item.plannedCount)")
            .font(.system(size: 13.0, weight: .semibold))
            .foregroundStyle(Color.secondaryText)
        }
      }
    }
    .detailsCard()
  }

  private var noActivitiesCard: some View {
    Text("No activities were scheduled for this plan.", bundle: .module)
      .font(.system(size: 13.0))
      .foregroundStyle(Color.secondaryText)
      .frame(maxWidth: .infinity, alignment: .leading)
      .detailsCard()
  }

  private func lifecycleButtons(for status: PlanStatus) -> some View {
    VStack(spacing: 5.0) {
      if status == .finished {
        Button(String(localized: "Create similar", bundle: .module)) {
          store.send(.view(.createSimilarButtonTapped))
        }
        .buttonStyle(PrimaryButtonStyle())
      } else if status == .archived {
        Button(String(localized: "Restore plan", bundle: .module)) {
          store.send(.view(.restoreButtonTapped))
        }
        .buttonStyle(PrimaryButtonStyle())

        Button(String(localized: "Create similar", bundle: .module)) {
          store.send(.view(.createSimilarButtonTapped))
        }
        .buttonStyle(CancelButtonStyle())
      }
    }
    .padding(.top, 5.0)
  }

  private func scheduleCard(
    days: [PlanDetailsContent.ScheduledDay],
    showsState: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 0.0) {
      ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
        if index > 0 { Divider().padding(.vertical, 15.0) }

        VStack(alignment: .leading, spacing: 10.0) {
          HStack(spacing: 10.0) {
            Text(day.title)
              .font(.system(size: 15.0, weight: .semibold))
              .foregroundStyle(Color.primaryText)

            Spacer(minLength: 10.0)

            if showsState, let state = day.state {
              dayStatePill(state)
            }
          }

          chipRow(day.activities, showsCompletion: showsState)
        }
      }
    }
    .detailsCard()
  }

  private func activityRow(_ activity: PlanDetailsContent.ActivityItem) -> some View {
    HStack(spacing: 10.0) {
      Image(systemName: activity.isDone ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 20.0, weight: .semibold))
        .foregroundStyle(activity.isDone ? Color.greenSuccess : Color.secondaryText)

      Text(activity.name)
        .font(.system(size: 15.0, weight: .medium))
        .foregroundStyle(Color.primaryText)

      Spacer(minLength: 10.0)

      Text(
        activity.isDone
          ? String(localized: "Done", bundle: .module)
          : String(localized: "Planned", bundle: .module)
      )
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(activity.isDone ? Color.greenSuccess : Color.secondaryText)
    }
  }

  private func chipRow(
    _ activities: [PlanDetailsContent.ActivityItem],
    showsCompletion: Bool = false
  ) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 5.0) {
        ForEach(activities) { activity in
          if showsCompletion {
            Chip(
              title: activity.name,
              systemImage: activity.isDone ? "checkmark.circle.fill" : "circle",
              systemImageColor: activity.isDone ? Color.greenSuccess : Color.secondaryText
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: activityAccessibilityLabel(activity)))
          } else {
            Chip(title: activity.name)
          }
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  private func activityAccessibilityLabel(
    _ activity: PlanDetailsContent.ActivityItem
  ) -> String {
    let status = activity.isDone
      ? String(localized: "Done", bundle: .module)
      : String(localized: "Planned", bundle: .module)
    return "\(activity.name), \(status)"
  }

  private func sectionTitle(_ title: String, trailing: String? = nil) -> some View {
    HStack(spacing: 10.0) {
      Text(verbatim: title)
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.sectionText)

      Spacer(minLength: 10.0)

      if let trailing {
        Text(trailing)
          .font(.system(size: 12.0))
          .foregroundStyle(Color.secondaryText)
      }
    }
    .padding(.top, 5.0)
  }

  private var statusPill: some View {
    Text(statusTitle)
      .font(.system(size: 12.0, weight: .semibold))
      .foregroundStyle(statusColor)
      .padding(.horizontal, 10.0)
      .frame(height: 26.0)
      .background(statusColor.opacity(0.12))
      .clipShape(Capsule())
  }

  private func dayStatePill(_ state: PlanDetailsContent.DayState) -> some View {
    let color: Color = switch state {
    case .done: .greenSuccess
    case .partial, .today: .sunburstOrange
    case .missed: .alertText
    case .upcoming: .secondaryText
    }

    return Text(String(localized: state.title, bundle: .module))
      .font(.system(size: 11.0, weight: .semibold))
      .foregroundStyle(color)
      .padding(.horizontal, 10.0)
      .frame(height: 24.0)
      .background(color.opacity(0.12))
      .clipShape(Capsule())
  }

  @ToolbarContentBuilder
  private var managementToolbar: some ToolbarContent {
    if store.allowsManagement {
      if content.status == .active {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { store.send(.view(.editButtonTapped)) }) {
            Image(systemName: "pencil.circle.fill")
              .accessibilityLabel(Text("Edit", bundle: .module))
          }
          .foregroundStyle(Color.actionBlue)
        }
      }

      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          if content.status == .active {
            Button(role: .destructive, action: { store.send(.view(.archiveButtonTapped)) }) {
              Label(String(localized: "Archive plan", bundle: .module), systemImage: "archivebox")
            }
          } else {
            Button(role: .destructive, action: { store.send(.view(.deleteButtonTapped)) }) {
              Label(String(localized: "Delete plan", bundle: .module), systemImage: "trash")
            }
          }
        } label: {
          Image(systemName: "ellipsis")
            .accessibilityLabel(Text("Plan actions", bundle: .module))
        }
        .foregroundStyle(Color.actionBlue)
      }
    }
  }

  private var statusTitle: String {
    switch content.status {
    case .active: String(localized: "Active", bundle: .module)
    case .finished: String(localized: "Finished", bundle: .module)
    case .archived: String(localized: "Archived", bundle: .module)
    }
  }

  private var statusColor: Color {
    switch content.status {
    case .active: .greenSuccess
    case .finished: .actionBlue
    case .archived: .secondaryText
    }
  }

  private var dateRangeText: String {
    let start = store.plan.startDate.formatted(template: "dMMMy", calendar: calendar)
    let end = store.plan.endDate.formatted(template: "dMMMy", calendar: calendar)
    return "\(start) – \(end)"
  }

  private var saveErrorBinding: Binding<Bool> {
    Binding(
      get: { store.isSaveErrorPresented },
      set: { isPresented in
        if !isPresented {
          store.send(.view(.saveErrorDismissed))
        }
      }
    )
  }

  private var progressSummary: String {
    let completed = content.progress.completedPlannedActivityCount
    let total = content.progress.totalPlannedActivityCount
    return String(
      localized: "\(completed) of \(total) planned activities complete",
      bundle: .module
    )
  }

  private var archiveConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.isArchiveConfirmationPresented },
      set: { isPresented in
        if !isPresented { store.send(.view(.archiveCancelled)) }
      }
    )
  }

  private var deleteConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.isDeleteConfirmationPresented },
      set: { isPresented in
        if !isPresented { store.send(.view(.deleteCancelled)) }
      }
    )
  }

  private var restoreUnavailableBinding: Binding<Bool> {
    Binding(
      get: { store.isRestoreUnavailableAlertPresented },
      set: { isPresented in
        if !isPresented { store.send(.view(.restoreUnavailableDismissed)) }
      }
    )
  }
}

private struct DetailsProgressBar: View {
  let value: Double

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.emphasisBackground)
        Capsule()
          .fill(Color.actionBlue)
          .frame(width: max(0.0, min(1.0, value)) * proxy.size.width)
      }
    }
    .frame(height: 6.0)
  }
}

private extension View {
  func detailsCard() -> some View {
    padding(15.0)
      .background(Color.formBackground)
      .clipShape(RoundedRectangle(cornerRadius: 14.0))
  }
}
