import Repositories
import Payment
import SwiftUI
import Utilities
import WidgetKit
import WidgetPlanProgress

struct PlanProgressWidgetProvider: AppIntentTimelineProvider, TodayProvidable {

  private let planRepository = PlanRepository.liveValue
  private let progressProvider = PlanProgressProvider()
  private let contentBuilder = PlanProgressWidgetContentBuilder()

  func placeholder(in context: Context) -> PlanProgressWidgetEntry {
    PlanProgressWidgetEntry(
      date: Date.now,
      content: PlanProgressWidgetContent(
        state: .partlyDoneToday,
        planID: UUID(),
        planName: "Learn Spanish",
        completedActivityCount: 3,
        totalActivityCount: 10,
        completedTodayCount: 1,
        totalTodayCount: 2,
        nextSessionDate: nil,
        referenceDate: Date.now
      ),
      configuration: PlanProgressAppIntent(),
      hasPremiumAccess: true
    )
  }

  func snapshot(
    for configuration: PlanProgressAppIntent,
    in context: Context
  ) async -> PlanProgressWidgetEntry {
    guard !context.isPreview else {
      return placeholder(in: context)
    }
    return await entry(for: configuration)
  }

  func timeline(
    for configuration: PlanProgressAppIntent,
    in context: Context
  ) async -> Timeline<PlanProgressWidgetEntry> {
    let entry = await entry(for: configuration)
    let refreshDate = (try? tomorrow) ?? Date.now.addingTimeInterval(15 * 60)
    return Timeline(entries: [entry], policy: .after(refreshDate))
  }

  private func entry(for configuration: PlanProgressAppIntent) async -> PlanProgressWidgetEntry {
    let hasPremiumAccess = PremiumAccess.hasAccess()
    guard hasPremiumAccess else {
      return PlanProgressWidgetEntry(
        date: .now,
        content: .noActivePlan(referenceDate: today),
        configuration: configuration,
        hasPremiumAccess: false
      )
    }
    do {
      let referenceDate = today
      let activePlans = try await planRepository.loadActivePlans(referenceDate)
      let plans = configuration.plan.map { selectedPlan in
        activePlans.filter { $0.id == selectedPlan.id }
      } ?? activePlans
      let snapshots = try await progressProvider.snapshots(for: plans)
      return PlanProgressWidgetEntry(
        date: referenceDate,
        content: contentBuilder.content(
          from: snapshots,
          referenceDate: referenceDate,
          calendar: .autoupdatingCurrent.utcCalendar
        ),
        configuration: configuration,
        hasPremiumAccess: true
      )
    } catch {
      return PlanProgressWidgetEntry(
        date: Date.now,
        content: .noActivePlan(referenceDate: today),
        configuration: configuration,
        hasPremiumAccess: true
      )
    }
  }
}

struct PlanProgressWidgetEntry: TimelineEntry {
  let date: Date
  let content: PlanProgressWidgetContent
  let configuration: PlanProgressAppIntent
  let hasPremiumAccess: Bool

  var deepLinkURL: URL {
    guard hasPremiumAccess else {
      return DeeplinkService.premium(PaywallEntryContext.planProgressWidget.rawValue)
    }
    return content.planID.map(DeeplinkService.plan) ?? DeeplinkService.plans
  }
}

struct PlanProgressWidgetEntryView: View {
  let entry: PlanProgressWidgetEntry

  var body: some View {
    Group {
      if entry.hasPremiumAccess {
        PlanProgressWidgetView(
          content: entry.content,
          calendar: .autoupdatingCurrent.utcCalendar
        )
      } else {
        PremiumLockedWidgetView(title: "Plan progress")
      }
    }
    .widgetURL(entry.deepLinkURL)
  }
}

struct PlanProgressWidget: Widget {
  let kind = "PlanProgressWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: PlanProgressAppIntent.self,
      provider: PlanProgressWidgetProvider()
    ) { entry in
      PlanProgressWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Plan progress · Plus")
    .description("Track a specific Plan with SnapDay Plus.")
    .contentMarginsDisabled()
    .supportedFamilies([.systemSmall])
  }
}
