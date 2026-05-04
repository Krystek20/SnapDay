import Foundation
import Dependencies
import WidgetKit

public actor WidgetReloader {

  private let reloadAction: @Sendable () -> Void
  private var pendingTask: Task<Void, Never>?

  public init(
    reloadAction: @escaping @Sendable () -> Void = {
      WidgetCenter.shared.reloadAllTimelines()
    }
  ) {
    self.reloadAction = reloadAction
  }

  public func requestReload(delay: Duration = .seconds(1)) {
    pendingTask?.cancel()
    pendingTask = Task { [reloadAction] in
      do {
        try await Task.sleep(for: delay)
        guard !Task.isCancelled else { return }
        reloadAction()
      } catch {
        // Ignore cancellation.
      }
    }
  }
}

extension DependencyValues {
  public var widgetReloader: WidgetReloader {
    get { self[WidgetReloader.self] }
    set { self[WidgetReloader.self] = newValue }
  }
}

extension WidgetReloader: DependencyKey {
  public static var liveValue: WidgetReloader {
    WidgetReloader()
  }
}
