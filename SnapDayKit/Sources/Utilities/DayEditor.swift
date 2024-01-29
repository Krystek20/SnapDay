import Foundation
import Models
import Dependencies

public struct DayEditor {
  public var updateDays: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> ()
  public var addActivity: @Sendable (_ activity: Activity, _ date: Date) async throws -> ()
  public var removeDayActivity: @Sendable (_ dayActivity: DayActivity, _ date: Date) async throws -> ()
  public var updateDayActivities: @Sendable (_ activity: Activity, _ fromDate: Date) async throws -> ()
  public var updateDayActivity: @Sendable (_ dayActivity: DayActivity, _ date: Date) async throws -> ()
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
      }
    )
  }

  public static var previewValue: DayEditor {
    DayEditor(
      updateDays: { _, _ in },
      addActivity: { _, _ in },
      removeDayActivity: { _, _ in },
      updateDayActivities: { _, _ in },
      updateDayActivity: {_, _ in }
    )
  }
}
