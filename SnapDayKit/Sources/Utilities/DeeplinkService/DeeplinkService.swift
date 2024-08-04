import Foundation
import Combine
import Dependencies

enum Schema: String {
  case widget
}

enum Host: String {
  case dashboard
}

enum Path: String {
  case addActivity
}

public extension DeeplinkService {
  static var addActivity: URL {
    var components = URLComponents()
    components.scheme = Schema.widget.rawValue
    components.host = Host.dashboard.rawValue
    components.path = "/" + Path.addActivity.rawValue
    return components.url ?? URL(filePath: "")
  }
}

public final class DeeplinkService {

  public enum Scene {
    case dashboard(DashboardAction?)
  }

  public enum DashboardAction {
    case addActivity
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
          }
        } else {
          deeplinkSubject.send(.dashboard(nil))
        }
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
