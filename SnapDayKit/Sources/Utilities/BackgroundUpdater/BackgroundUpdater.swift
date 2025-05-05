import Foundation
import BackgroundTasks
import Dependencies

public enum BackgroundUpdaterIdentifier: String {
  case createDay = "com.mobilove.snapday.create_day"
}

public final class BackgroundUpdater {

  public enum BackgroundUpdaterError: Error {
    case notRegistered
  }

  // MARK: - Properties

  private let taskScheduler: BGTaskScheduler
  @Dependency(\.date) private var date
  @Dependency(\.utcCalendar) private var calendar

  // MARK: - Initialization

  public init(taskScheduler: BGTaskScheduler = .shared) {
    self.taskScheduler = taskScheduler
  }

  // MARK: - Public

  public func registerBackgroundTask(launchHandler: @escaping () async throws -> Void) throws {
    let isRegistered = taskScheduler.register(
      forTaskWithIdentifier: BackgroundUpdaterIdentifier.createDay.rawValue,
      using: nil,
      launchHandler: { bgTask in
        guard let bgTask = bgTask as? BGAppRefreshTask else {
          return bgTask.setTaskCompleted(success: false)
        }

        let task = Task { [weak self] in
          guard let self else { throw CancellationError() }
          do {
            try await scheduleCreatingDayBackgroundTask()
            try await launchHandler()
            bgTask.setTaskCompleted(success: !Task.isCancelled)
          } catch {
            bgTask.setTaskCompleted(success: false)
          }
        }

        bgTask.expirationHandler = {
          task.cancel()
        }
      }
    )
    guard isRegistered else { throw BackgroundUpdaterError.notRegistered }
    Task {
      try await scheduleCreatingDayBackgroundTask()
    }
  }

  public func scheduleCreatingDayBackgroundTask() async throws {
    let pendingTasks = await taskScheduler.pendingTaskRequests()
    guard !pendingTasks.contains(where: { $0.identifier == BackgroundUpdaterIdentifier.createDay.rawValue }) else { return }
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
