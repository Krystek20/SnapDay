public struct DaySummary {

  // MARK: - Properties

  private let day: Day

  // MARK: - Initialization

  public init(day: Day) {
    self.day = day
  }

  // MARK: - Public

  public var duration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      result += dayActivity.totalDuration
    })
  }

  public var remaingDuration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      guard !dayActivity.isDone else { return }
      result += dayActivity.duration
      result += dayActivity.dayActivityTasks.reduce(into: Int.zero, { result, dayActivityTask in
        guard !dayActivityTask.isDone else { return }
        result += dayActivityTask.duration
      })
    })
  }
}
