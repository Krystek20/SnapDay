import Foundation
import Models
import Dependencies
import struct Repositories.Transactions

public struct DayEditor {
  public var prepareDays: @Sendable (_ activities: [Activity], _ dateRange: ClosedRange<Date>) async throws -> [Day]
  public var updateDays: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> ()
  public var addActivity: @Sendable (_ activity: Activity, _ date: Date) async throws -> ()
  public var removeDayActivity: @Sendable (_ dayActivity: DayActivity, _ date: Date) async throws -> ()
  public var updateDayActivities: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> ()
  public var updateDayActivity: @Sendable (_ dayActivity: DayActivity, _ date: Date) async throws -> ()
  public var applyChanges: @Sendable (_ transactions: Transactions) async throws -> [Date]
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
      updateDays: { activity, date in
        try await DayUpdater().addActivity(activity, from: date)
      },
      addActivity: { activity, date in
        try await DayUpdater().addActivity(activity, to: date, createdByUser: true)
      },
      removeDayActivity: { activity, date in
        try await DayUpdater().remove(activity, date: date)
      },
      updateDayActivities: { activity, date in
        try await DayUpdater().updateDaysByUpdatedActivity(activity, from: date)
      },
      updateDayActivity: { dayActivity, date in
        try await DayUpdater().updateDayActivity(dayActivity, to: date)
      },
      applyChanges: { transactions in
        try await DayUpdater().applyChanges(transactions)
      }
    )
  }
}
