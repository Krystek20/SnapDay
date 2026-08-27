import Foundation
import Combine
import Dependencies

enum Schema: String {
  case widget
}

enum Host: String {
  case dashboard
  case plans
  case premium
}

enum Path: String {
  case addActivity
  case dictate
}

public extension DeeplinkService {
  static var plans: URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.plans.rawValue
    return components.url ?? URL(filePath: "")
  }

  static func plan(_ identifier: UUID) -> URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.plans.rawValue
    components.path = "/" + identifier.uuidString
    return components.url ?? URL(filePath: "")
  }

  static var addActivity: URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.dashboard.rawValue
    components.path = "/" + Path.addActivity.rawValue
    return components.url ?? URL(filePath: "")
  }

  static var dictate: URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.dashboard.rawValue
    components.path = "/" + Path.dictate.rawValue
    return components.url ?? URL(filePath: "")
  }

  static func premium(_ context: String) -> URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.premium.rawValue
    components.path = "/" + context
    return components.url ?? URL(filePath: "")
  }
}

public final class DeeplinkService {

  public enum Scene {
    case dashboard(DashboardAction?)
    case plans(UUID?)
    case premium(String)
  }

  public enum DashboardAction {
    case addActivity
    case dictate
  }

  // MARK: - Properties

  public var deeplinkPublisher: AnyPublisher<Scene?, Never> { deeplinkSubject.eraseToAnyPublisher() }
  private let deeplinkSubject = CurrentValueSubject<Scene?, Never>(nil)

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func handleUrl(_ url: URL) {
    guard let urlScheme = url.scheme,
          let schema = Schema(rawValue: urlScheme),
          let urlHost = url.host(),
          let host = Host(rawValue: urlHost) else { return }
    switch schema {
    case .widget:
      switch host {
      case .dashboard:
        if let path = Path(rawValue: url.lastPathComponent) {
          switch path {
          case .addActivity:
            deeplinkSubject.send(.dashboard(.addActivity))
          case .dictate:
            deeplinkSubject.send(.dashboard(.dictate))
          }
        } else {
          deeplinkSubject.send(.dashboard(nil))
        }
      case .plans:
        deeplinkSubject.send(.plans(UUID(uuidString: url.lastPathComponent)))
      case .premium:
        deeplinkSubject.send(.premium(url.lastPathComponent))
      }
    }
  }

  public func consume() {
    deeplinkSubject.send(nil)
  }
}

extension DependencyValues {
  public var deeplinkService: DeeplinkService {
    get { self[DeeplinkService.self] }
    set { self[DeeplinkService.self] = newValue }
  }
}

extension DeeplinkService: DependencyKey {
  public static var liveValue: DeeplinkService {
    DeeplinkService()
  }
}
