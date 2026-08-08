import Foundation
import Models
import Utilities

public struct PlanProgressWidgetContent: Equatable {

  public enum State: Equatable {
    case noActivePlan
    case dueToday
    case partlyDoneToday
    case todayComplete
    case noActivitiesToday
  }

  public let state: State
  public let planID: Plan.ID?
  public let planName: String
  public let completedActivityCount: Int
  public let totalActivityCount: Int
  public let completedTodayCount: Int
  public let totalTodayCount: Int
  public let nextSessionDate: Date?
  public let referenceDate: Date

  public var fractionComplete: Double {
    guard totalActivityCount > 0 else { return .zero }
    return Double(completedActivityCount) / Double(totalActivityCount)
  }

  public var percentComplete: Int {
    Int((fractionComplete * 100).rounded())
  }

  public init(
    state: State,
    planID: Plan.ID?,
    planName: String,
    completedActivityCount: Int,
    totalActivityCount: Int,
    completedTodayCount: Int,
    totalTodayCount: Int,
    nextSessionDate: Date?,
    referenceDate: Date
  ) {
    self.state = state
    self.planID = planID
    self.planName = planName
    self.completedActivityCount = completedActivityCount
    self.totalActivityCount = totalActivityCount
    self.completedTodayCount = completedTodayCount
    self.totalTodayCount = totalTodayCount
    self.nextSessionDate = nextSessionDate
    self.referenceDate = referenceDate
  }

  public static func noActivePlan(referenceDate: Date) -> Self {
    Self(
      state: .noActivePlan,
      planID: nil,
      planName: "Plans",
      completedActivityCount: .zero,
      totalActivityCount: .zero,
      completedTodayCount: .zero,
      totalTodayCount: .zero,
      nextSessionDate: nil,
      referenceDate: referenceDate
    )
  }
}

public struct PlanProgressWidgetContentBuilder {

  public init() { }

  public func content(
    from snapshots: [PlanProgressSnapshot],
    referenceDate: Date,
    calendar: Calendar
  ) -> PlanProgressWidgetContent {
    let startOfDay = calendar.startOfDay(for: referenceDate)
    let candidates = snapshots.map {
      candidate(from: $0, referenceDate: startOfDay, calendar: calendar)
    }

    return candidates.min(by: candidateIsMoreRelevant)?.content
      ?? .noActivePlan(referenceDate: startOfDay)
  }

  private func candidate(
    from snapshot: PlanProgressSnapshot,
    referenceDate: Date,
    calendar: Calendar
  ) -> Candidate {
    let occurrences = snapshot.occurrences.deduplicatedByID()
    let completedDayActivityIDs = Set(
      snapshot.dayActivities.lazy.filter(\.isDone).map(\.id)
    )
    let todayOccurrences = occurrences.filter {
      calendar.isDate($0.date, inSameDayAs: referenceDate)
    }
    let completedTodayCount = todayOccurrences.lazy.filter {
      $0.dayActivityID.map(completedDayActivityIDs.contains) ?? false
    }.count
    let pendingTodayCount = todayOccurrences.count - completedTodayCount
    let progress = snapshot.plan.progress(
      from: occurrences,
      dayActivities: snapshot.dayActivities
    )
    let nextSessionDate = occurrences.lazy
      .filter {
        $0.date >= referenceDate
          && !($0.dayActivityID.map(completedDayActivityIDs.contains) ?? false)
      }
      .map(\.date)
      .min()
    let state: PlanProgressWidgetContent.State
    let priority: Int

    if !todayOccurrences.isEmpty, pendingTodayCount > 0 {
      state = completedTodayCount > 0 ? .partlyDoneToday : .dueToday
      priority = 0
    } else if !todayOccurrences.isEmpty {
      state = .todayComplete
      priority = 1
    } else {
      state = .noActivitiesToday
      priority = 2
    }

    return Candidate(
      content: PlanProgressWidgetContent(
        state: state,
        planID: snapshot.plan.id,
        planName: snapshot.plan.name,
        completedActivityCount: progress.completedPlannedActivityCount,
        totalActivityCount: progress.totalPlannedActivityCount,
        completedTodayCount: completedTodayCount,
        totalTodayCount: todayOccurrences.count,
        nextSessionDate: nextSessionDate,
        referenceDate: referenceDate
      ),
      priority: priority,
      nextSessionDate: nextSessionDate,
      planStartDate: snapshot.plan.startDate
    )
  }

  private func candidateIsMoreRelevant(_ lhs: Candidate, _ rhs: Candidate) -> Bool {
    if lhs.priority != rhs.priority {
      return lhs.priority < rhs.priority
    }
    if lhs.nextSessionDate != rhs.nextSessionDate {
      return (lhs.nextSessionDate ?? .distantFuture) < (rhs.nextSessionDate ?? .distantFuture)
    }
    if lhs.planStartDate != rhs.planStartDate {
      return lhs.planStartDate < rhs.planStartDate
    }
    if lhs.content.planName != rhs.content.planName {
      return lhs.content.planName.localizedStandardCompare(rhs.content.planName) == .orderedAscending
    }
    return lhs.content.planID?.uuidString ?? "" < rhs.content.planID?.uuidString ?? ""
  }
}

private struct Candidate {
  let content: PlanProgressWidgetContent
  let priority: Int
  let nextSessionDate: Date?
  let planStartDate: Date
}
