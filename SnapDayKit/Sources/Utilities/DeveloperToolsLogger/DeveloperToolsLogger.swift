import Foundation

public final class DeveloperToolsLogger {

  public enum DeveloperToolsEvent {
    public enum RefreshEvent: String {
      case setup
      case runInBackground
    }
    case refresh(RefreshEvent)

    var stringValue: String {
      switch self {
      case .refresh(let refreshEvent):
        "refresh:" + refreshEvent.rawValue
      }
    }
  }

  public static let shared = DeveloperToolsLogger()
  private let key = "developer_events"

  public var events: [String] {
    userDefaults.array(forKey: key) as? [String] ?? []
  }

  private let userDefaults: UserDefaults

  // MARK: - Initialization

  private init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  // MARK: - Public

  public func append(_ event: DeveloperToolsEvent) {
    var allEvents = events
    if allEvents.count > 20 {
      allEvents.removeLast()
    }
    let formatter = ISO8601DateFormatter()
    let date = formatter.string(from: Date())
    allEvents.insert(date + " - " + event.stringValue, at: .zero)
    userDefaults.setValue(allEvents, forKey: key)
  }
}
