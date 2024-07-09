import Foundation

public final class DeveloperToolsLogger {

  public enum DeveloperToolsEvent {
    public enum RefreshEvent: String {
      case setup
      case setupInBackground
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
    let formatter = ISO8601DateFormatter()
    let date = formatter.string(from: Date())
    let separation = " - "
    if let lastElement = allEvents.last?.components(separatedBy: separation).last, lastElement == event.stringValue {
      let counter = allEvents.last?.components(separatedBy: separation).first ?? "1"
      let intCounter = Int(counter) ?? 1
      allEvents[allEvents.count - 1] = String(intCounter + 1) + separation + date + separation + event.stringValue
    } else {
      allEvents.insert("1" + separation + date + separation + event.stringValue, at: .zero)
    }
    userDefaults.setValue(Array(allEvents.suffix(5)), forKey: key)
  }
}
