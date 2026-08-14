import Foundation
import ComposableArchitecture
import Models
import Testing
@testable import Dashboard

@MainActor
struct DashboardTests {

  @Test
  func dashboardTitleFormatsStoredDayInUTC() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let saturday = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))
    )
    let state = DashboardFeature.State(date: saturday)

    #expect(state.formattedTitle(locale: Locale(identifier: "en_US")) == "Saturday, 18 Jul 2026")
  }

  @Test
  func planSummaryCalculatesProgressAndNextIncompleteSession() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let monday = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
    )
    let friday = try #require(calendar.date(byAdding: .day, value: 4, to: monday))
    let planID = UUID()
    let activityID = UUID()
    let completedDayActivityID = UUID()
    let plan = Plan(
      id: planID,
      name: "Learn Spanish",
      startDate: monday,
      endDate: friday,
      duration: .custom,
      schedule: []
    )
    let occurrences = [
      PlanOccurrence(
        planID: planID,
        activityID: activityID,
        date: monday,
        dayActivityID: completedDayActivityID
      ),
      PlanOccurrence(planID: planID, activityID: activityID, date: friday)
    ]
    let completedActivity = DayActivity(
      id: completedDayActivityID,
      date: monday,
      doneDate: monday,
      isGeneratedAutomatically: true
    )

    let summary = DashboardPlanSummary(
      plan: plan,
      occurrences: occurrences,
      dayActivities: [completedActivity],
      date: monday,
      calendar: calendar
    )

    #expect(summary.title == "Learn Spanish")
    #expect(summary.progress.completedPlannedActivityCount == 1)
    #expect(summary.progress.totalPlannedActivityCount == 2)
    #expect(summary.progress.percentComplete == 50)
    #expect(summary.nextSessionDate == friday)
  }

  @Test
  func planSummaryMovesFromCompletedSaturdayToSunday() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let saturday = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))
    )
    let sunday = try #require(calendar.date(byAdding: .day, value: 1, to: saturday))
    let planID = UUID()
    let activityID = UUID()
    let completedDayActivityID = UUID()
    let plan = Plan(
      id: planID,
      name: "Weekend plan",
      startDate: saturday,
      endDate: sunday,
      duration: .custom,
      schedule: []
    )
    let completedActivity = DayActivity(
      id: completedDayActivityID,
      date: saturday,
      doneDate: saturday,
      isGeneratedAutomatically: true
    )

    let summary = DashboardPlanSummary(
      plan: plan,
      occurrences: [
        PlanOccurrence(
          planID: planID,
          activityID: activityID,
          date: saturday,
          dayActivityID: completedDayActivityID
        ),
        PlanOccurrence(planID: planID, activityID: activityID, date: sunday)
      ],
      dayActivities: [completedActivity],
      date: saturday,
      calendar: calendar
    )
    let configuration = DashboardPlansSummaryView.Configuration(
      summary: summary,
      calendar: calendar,
      locale: Locale(identifier: "en_US")
    )

    #expect(summary.nextSessionDate == sunday)
    #expect(configuration.metadata?.leadingText == "Next session: Tomorrow")
  }

  @Test
  func planSummaryKeepsPendingSessionOnToday() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let today = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 21))
    )
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let plan = Plan(
      id: UUID(),
      name: "Daily plan",
      startDate: today,
      endDate: tomorrow,
      duration: .custom,
      schedule: []
    )
    let summary = DashboardPlanSummary(
      plan: plan,
      occurrences: [
        PlanOccurrence(planID: plan.id, activityID: UUID(), date: today),
        PlanOccurrence(planID: plan.id, activityID: UUID(), date: tomorrow)
      ],
      dayActivities: [],
      date: today,
      calendar: calendar
    )
    let configuration = DashboardPlansSummaryView.Configuration(
      summary: summary,
      calendar: calendar,
      locale: Locale(identifier: "en_US")
    )

    #expect(summary.nextSessionDate == today)
    #expect(configuration.metadata?.leadingText == "Next session: Today")
  }

  @Test
  func plansLoadedUpdatesDashboardSummaries() async {
    let date = Date(timeIntervalSince1970: 1_752_364_800)
    let plan = Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: date,
      endDate: date,
      duration: .sevenDays,
      schedule: []
    )
    let summary = DashboardPlanSummary(
      plan: plan,
      occurrences: [],
      dayActivities: [],
      date: date,
      calendar: .current
    )
    let store = TestStore(
      initialState: DashboardFeature.State(date: date),
      reducer: { DashboardFeature() }
    )

    await store.send(.internal(.plansLoaded([summary]))) {
      $0.planSummaries = [summary]
    }
  }

  @Test
  func notificationPromptRequiresContent() {
    let date = Date(timeIntervalSince1970: 1_752_364_800)
    var state = DashboardFeature.State(date: date)

    state.canRequestNotificationAuthorization = true
    #expect(!state.shouldShowNotificationPrompt)

    state.selectedDay = Day(
      id: UUID(),
      date: date,
      activities: [
        DayActivity(
          id: UUID(),
          date: date,
          isGeneratedAutomatically: false
        )
      ]
    )

    #expect(state.shouldShowNotificationPrompt)
  }

  @Test
  func notificationPromptDismissalIsRemembered() async throws {
    let suiteName = "DashboardTests.notificationPrompt.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    var state = DashboardFeature.State(date: Date())
    state.canRequestNotificationAuthorization = true
    let store = TestStore(
      initialState: state,
      reducer: { DashboardFeature(userDefaults: userDefaults) }
    )

    await store.send(.view(.notificationPromptDismissed)) {
      $0.canRequestNotificationAuthorization = false
    }

    #expect(userDefaults.bool(forKey: "notificationPromptDismissed"))
  }

  @Test
  func failedNotificationAuthorizationCanBeRetried() async throws {
    let suiteName = "DashboardTests.notificationFailure.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let store = TestStore(
      initialState: DashboardFeature.State(date: Date()),
      reducer: { DashboardFeature(userDefaults: userDefaults) }
    )

    await store.send(.internal(.notificationAuthorizationRequestFailed)) {
      $0.canRequestNotificationAuthorization = true
    }

    #expect(!userDefaults.bool(forKey: "notificationPromptDismissed"))
  }

  @Test
  func completedNotificationAuthorizationIsRemembered() async throws {
    let suiteName = "DashboardTests.notificationSuccess.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    var state = DashboardFeature.State(date: Date())
    state.canRequestNotificationAuthorization = true
    let store = TestStore(
      initialState: state,
      reducer: { DashboardFeature(userDefaults: userDefaults) }
    )

    await store.send(.internal(.notificationAuthorizationRequestCompleted)) {
      $0.canRequestNotificationAuthorization = false
    }

    #expect(userDefaults.bool(forKey: "notificationPromptDismissed"))
  }

  @Test
  func planSummaryTapDelegatesSelectedPlan() async {
    let date = Date(timeIntervalSince1970: 1_752_364_800)
    let plan = Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: date,
      endDate: date,
      duration: .sevenDays,
      schedule: []
    )
    let store = TestStore(
      initialState: DashboardFeature.State(date: date),
      reducer: { DashboardFeature() }
    )

    await store.send(.view(.planSummaryTapped(plan)))
    await store.receive(.delegate(.planTapped(plan)))
  }

  @Test
  func planSummaryConfigurationFormatsTomorrowUsingProvidedCalendar() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let today = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
    )
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let plan = Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: today,
      endDate: tomorrow,
      duration: .custom,
      schedule: []
    )
    let summary = DashboardPlanSummary(
      plan: plan,
      occurrences: [
        PlanOccurrence(planID: plan.id, activityID: UUID(), date: tomorrow)
      ],
      dayActivities: [],
      date: today,
      calendar: calendar
    )

    let configuration = DashboardPlansSummaryView.Configuration(
      summary: summary,
      calendar: calendar,
      locale: Locale(identifier: "en_US")
    )

    #expect(configuration.metadata?.leadingText == "Next session: Tomorrow")
  }
}
