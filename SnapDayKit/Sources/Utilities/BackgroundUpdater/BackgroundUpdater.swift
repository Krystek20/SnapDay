import Foundation
import BackgroundTasks
import Dependencies

public enum BackgroundUpdaterIdentifier: String {
  case createDay = "com.mobilove.snapday.create_day"
}

public final class BackgroundUpdater {

  // MARK: - Properties

  private let taskScheduler: BGTaskScheduler
  @Dependency(\.date) private var date
  @Dependency(\.calendar) private var calendar

  // MARK: - Initialization

  public init(taskScheduler: BGTaskScheduler = .shared) {
    self.taskScheduler = taskScheduler
  }

  // MARK: - Public

  public func scheduleCreatingDayBackgroundTask() async throws {
    let pendingTasks = await taskScheduler.pendingTaskRequests()
    guard
      !pendingTasks.contains(where: { $0.identifier == BackgroundUpdaterIdentifier.createDay.rawValue })
    else { return }
    let request = BGAppRefreshTaskRequest(identifier: BackgroundUpdaterIdentifier.createDay.rawValue)
    request.earliestBeginDate = calendar.date(byAdding: .hour, value: 1, to: date.now)
    try taskScheduler.submit(request)
  }
}

extension DependencyValues {
  public var backgroundUpdater: BackgroundUpdater {
    get { self[BackgroundUpdater.self] }
    set { self[BackgroundUpdater.self] = newValue }
  }
}

extension BackgroundUpdater: DependencyKey {
  public static var liveValue: BackgroundUpdater {
    BackgroundUpdater()
  }
}
