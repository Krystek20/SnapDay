import Foundation
import BackgroundTasks
import Dependencies

public enum BackgroundUpdaterIdentifier: String {
  case createDay = "com.mobilove.snapday.create_day"
}

public final class BackgroundUpdater {

  public enum BackgroundUpdaterError: Error {
    case tomorrowCanNotBeCreated
  }

  // MARK: - Properties

  private let taskScheduler: BGTaskScheduler
  @Dependency(\.date) private var date
  @Dependency(\.calendar) private var calendar

  private var tomorrow: Date {
    get throws {
      guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date.now) else {
        throw BackgroundUpdaterError.tomorrowCanNotBeCreated
      }
      var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
      tomorrowComponents.hour = 18
      tomorrowComponents.minute = .zero
      guard let tomorrowWithHours = calendar.date(from: tomorrowComponents) else {
        throw BackgroundUpdaterError.tomorrowCanNotBeCreated
      }
      return tomorrowWithHours
    }
  }

  // MARK: - Initialization

  public init(taskScheduler: BGTaskScheduler = .shared) {
    self.taskScheduler = taskScheduler
  }

  // MARK: - Public

  public func scheduleCreatingDayBackgroundTask() throws {
    taskScheduler.cancelAllTaskRequests()
    DeveloperToolsLogger.shared.append(.refresh(.setup))
    let request = BGAppRefreshTaskRequest(identifier: BackgroundUpdaterIdentifier.createDay.rawValue)
    request.earliestBeginDate = try tomorrow
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
