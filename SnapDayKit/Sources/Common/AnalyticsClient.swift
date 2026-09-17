import ComposableArchitecture
import Foundation
import TelemetryDeck

public struct AnalyticsClient: Sendable {
  public var track: @Sendable (AnalyticsEvent) -> Void

  public init(track: @escaping @Sendable (AnalyticsEvent) -> Void) {
    self.track = track
  }
}

extension AnalyticsClient: DependencyKey {
  public static let liveValue = Self { event in
    ProductAnalytics.track(event)
  }

  public static let testValue = Self { _ in }
}

public extension DependencyValues {
  var analyticsClient: AnalyticsClient {
    get { self[AnalyticsClient.self] }
    set { self[AnalyticsClient.self] = newValue }
  }
}

public enum ProductAnalytics {
  private static let appIDKey = "TelemetryDeckAppID"
  private static let state = ProductAnalyticsState()

  public static func start(bundle: Bundle = .main) {
    guard
      let appID = bundle.object(forInfoDictionaryKey: appIDKey) as? String,
      !appID.isEmpty,
      !appID.contains("$(")
    else {
      #if DEBUG
      print("[ProductAnalytics] TelemetryDeck app ID is missing; analytics is disabled.")
      #endif
      return
    }

    TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
    state.markStarted()
  }

  fileprivate static func track(_ event: AnalyticsEvent) {
    guard state.isStarted else { return }
    TelemetryDeck.signal(event.name, parameters: event.parameters)
  }
}

private final class ProductAnalyticsState: @unchecked Sendable {
  private let lock = NSLock()
  private var started = false

  var isStarted: Bool {
    lock.withLock { started }
  }

  func markStarted() {
    lock.withLock { started = true }
  }
}
