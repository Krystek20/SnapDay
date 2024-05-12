import UserNotifications
import Dependencies

public enum UserNotificationidentifier: String {
  case eveningSummary = "com.mobilove.snapday.notification.eveningSummary"

  var categoryIdentifier: String {
    switch self {
    case .eveningSummary:
      return "EVENING_SUMMARY"
    }
  }
}

public protocol UserNotificationCenter {
  var delegate: (any UNUserNotificationCenterDelegate)? { get set }
  func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
  func add(_ request: UNNotificationRequest) async throws
  func pendingNotificationRequests() async -> [UNNotificationRequest]
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UNUserNotificationCenter: UserNotificationCenter { }

public final class UserNotificationCenterProvider: NSObject {

  // MARK: - Properties

  @Dependency(\.calendar) private var calendar
  private var userNotificationCenter: UserNotificationCenter

  // MARK: - Initialization

  public init(userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
    self.userNotificationCenter = userNotificationCenter
    super.init()
    self.userNotificationCenter.delegate = self
  }

  // MARK: - Public

  public func requestAuthorization() async throws -> Bool {
    try await userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
  }

  public func registerCategories() {
    let category = UNNotificationCategory(
      identifier: UserNotificationidentifier.eveningSummary.categoryIdentifier,
      actions: [],
      intentIdentifiers: []
    )
    userNotificationCenter.setNotificationCategories([category])
  }

  public func schedule(identifier: UserNotificationidentifier) async throws {
    let isNotificationScheduled = await userNotificationCenter.pendingNotificationRequests().contains(where: {
      $0.identifier == identifier.rawValue
    })
    guard !isNotificationScheduled else { return }

    let content = UNMutableNotificationContent()
    content.title = "Good Evening!"
    content.body = "Don't forget to review your day and prepare for tomorrow."
    content.sound = .default
    content.categoryIdentifier = identifier.categoryIdentifier

    var dateComponents = DateComponents()
    dateComponents.calendar = calendar

    dateComponents.hour = 21
    dateComponents.minute = 15

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: identifier.rawValue, content: content, trigger: trigger)
    try await userNotificationCenter.add(request)
  }
}

extension UserNotificationCenterProvider: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    [.badge, .sound, .banner, .list]
  }
}
