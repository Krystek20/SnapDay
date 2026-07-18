import ComposableArchitecture
import Models
import Resources
import SwiftUI
import UiComponents

@MainActor
public struct PlanDetailsView: View {

  @Bindable private var store: StoreOf<PlanDetailsFeature>
  @Environment(\.calendar) private var calendar

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
    .navigationTitle(Text("Plan Detail", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { managementToolbar }
    .task { await store.send(.view(.task)).finish() }
    .alert(
      String(localized: "Archive this Plan?", bundle: .module),
      isPresented: archiveConfirmationBinding
    ) {
      Button(
        String(localized: "Archive Plan", bundle: .module),
        role: .destructive,
        action: { store.send(.view(.archiveConfirmed)) }
      )
      Button(
        String(localized: "Cancel", bundle: .module),
        role: .cancel,
        action: { store.send(.view(.archiveCancelled)) }
      )
    } message: {
      Text("The Plan will move to History. Completed activities and progress will be kept.", bundle: .module)
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
      "TODAY",
      trailing: (store.referenceDate ?? .now).formatted(.dateTime.weekday(.wide))
    )

    if content.todayActivities.isEmpty {
      restDayCard
    } else {
      todayCard
    }

    sectionTitle("THIS WEEK")
    scheduleCard(days: content.scheduledDays, showsState: true)
  }

  private var todayCard: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        Text(verbatim: "\(content.completedTodayCount) of \(content.todayActivities.count) activities complete")
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

        Text("This Plan does not generate anything today. Your daily list can still contain non-Plan activities.", bundle: .module)
          .font(.system(size: 13.0))
          .foregroundStyle(Color.secondaryText)
      }

      if let nextDay = content.nextPlannedDay {
        Divider()

        VStack(alignment: .leading, spacing: 10.0) {
          Text("NEXT PLANNED DAY", bundle: .module)
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
    sectionTitle("RESULT")

    VStack(alignment: .leading, spacing: 15.0) {
      Text(progressSummary)
        .font(.system(size: 17.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)

      Text("This Plan has reached its end date. Its schedule and progress are now read-only.", bundle: .module)
        .font(.system(size: 13.0))
        .foregroundStyle(Color.secondaryText)

      DetailsProgressBar(value: content.progress.fractionComplete)
    }
    .detailsCard()

    sectionTitle("SCHEDULE")
    scheduleCard(days: content.scheduledDays, showsState: false)
  }

  @ViewBuilder
  private var archivedContent: some View {
    sectionTitle("STATUS")

    VStack(alignment: .leading, spacing: 5.0) {
      Text("This Plan is not active", bundle: .module)
        .font(.system(size: 17.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)

      Text("It no longer generates activities. Its previous schedule and progress are kept for reference.", bundle: .module)
        .font(.system(size: 13.0))
        .foregroundStyle(Color.secondaryText)
    }
    .detailsCard()

    sectionTitle("PREVIOUS SCHEDULE")
    scheduleCard(days: content.scheduledDays, showsState: false)
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

          chipRow(day.activities)
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

      Text(verbatim: activity.isDone ? "Done" : "Planned")
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(activity.isDone ? Color.greenSuccess : Color.secondaryText)
    }
  }

  private func chipRow(_ activities: [PlanDetailsContent.ActivityItem]) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 5.0) {
        ForEach(activities) { activity in
          Chip(title: activity.name)
        }
      }
    }
    .scrollIndicators(.hidden)
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

    return Text(state.title)
      .font(.system(size: 11.0, weight: .semibold))
      .foregroundStyle(color)
      .padding(.horizontal, 10.0)
      .frame(height: 24.0)
      .background(color.opacity(0.12))
      .clipShape(Capsule())
  }

  @ToolbarContentBuilder
  private var managementToolbar: some ToolbarContent {
    if store.allowsManagement, content.status == .active {
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: { store.send(.view(.editButtonTapped)) }) {
          Image(systemName: "pencil.circle.fill")
            .accessibilityLabel(Text("Edit", bundle: .module))
        }
        .foregroundStyle(Color.actionBlue)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button(role: .destructive, action: { store.send(.view(.archiveButtonTapped)) }) {
            Label(String(localized: "Archive Plan", bundle: .module), systemImage: "archivebox")
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
    let start = store.plan.startDate.formatted(.dateTime.day().month(.abbreviated).year())
    let end = store.plan.endDate.formatted(.dateTime.day().month(.abbreviated).year())
    return "\(start) - \(end)"
  }

  private var progressSummary: String {
    "\(content.progress.completedPlannedActivityCount) of \(content.progress.totalPlannedActivityCount) planned activities complete"
  }

  private var archiveConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.isArchiveConfirmationPresented },
      set: { isPresented in
        if !isPresented { store.send(.view(.archiveCancelled)) }
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
