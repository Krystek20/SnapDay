import Foundation
import Models
import Dependencies
import struct Repositories.Transactions

public struct DayEditor {
  public var prepareDays: @Sendable (_ activities: [Activity], _ dateRange: ClosedRange<Date>) async throws -> [Day]
  public var saveDayActivity: @Sendable (_ dayActivity: DayActivity) async throws -> Void
  public var saveDayActivities: @Sendable (_ dayActivities: [DayActivity]) async throws -> Void
  public var removeDayActivity: @Sendable (_ dayActivity: DayActivity) async throws -> Void
  public var updateDayActivities: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> Void
  public var removeDayActivities: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> Void
  public var moveDayActivity: @Sendable (_ dayActivity: DayActivity, _ toDate: Date) async throws -> Void
  public var copyDayActivity: @Sendable (_ dayActivity: DayActivity, _ dates: [Date]) async throws -> Void
}

extension DependencyValues {
  public var dayEditor: DayEditor {
    get { self[DayEditor.self] }
    set { self[DayEditor.self] = newValue }
  }
}

extension DayEditor: DependencyKey {
  public static var liveValue: DayEditor {
    DayEditor(
      prepareDays: { activities, dateRange in
        try await DayUpdater().prepareDays(for: activities, in: dateRange)
      },
      saveDayActivity: { dayActivity in
        try await DayUpdater().saveDayActivity(dayActivity)
      },
      saveDayActivities: { dayActivities in
        try await DayUpdater().saveDayActivities(dayActivities)
      },
      removeDayActivity: { dayActivity in
        try await DayUpdater().removeDayActivity(dayActivity)
      },
      updateDayActivities: { activity, date in
        try await DayUpdater().updateDaysByUpdatedActivity(activity, from: date)
      },
      removeDayActivities: { activity, date in
        try await DayUpdater().updateDaysByRemovedActivity(activity, from: date)
      },
      moveDayActivity: { dayActivity, toDate in
        try await DayUpdater().moveDayActivity(dayActivity, toDate: toDate)
      },
      copyDayActivity: { dayActivity, dates in
        try await DayUpdater().copyDayActivity(dayActivity, to: dates)
      }
    )
  }
}
