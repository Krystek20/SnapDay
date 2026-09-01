import Foundation
import SentrySwift

public enum Telemetry {

  private static let dsnKey = "SentryDSN"

  public static func start(bundle: Bundle = .main) {
    guard let dsn = bundle.object(forInfoDictionaryKey: dsnKey) as? String,
          !dsn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          dsn != "$(SENTRY_DSN)" else {
      return
    }

    SentrySDK.start { options in
      options.dsn = dsn
      options.sendDefaultPii = false
      options.enableAutoSessionTracking = true
      options.environment = configurationName
    }
  }

  public static func breadcrumb(
    _ stage: String,
    category: String = "collaboration.invitation",
    data: [String: Any] = [:]
  ) {
    let breadcrumb = Breadcrumb(level: .info, category: category)
    breadcrumb.message = stage
    for (key, value) in data {
      breadcrumb.setData(value: value, key: key)
    }
    SentrySDK.addBreadcrumb(breadcrumb)
  }

  public static func capture(
    _ error: any Error,
    stage: String,
    tags: [String: String] = [:]
  ) {
    guard !(error is CancellationError) else { return }

    let nsError = error as NSError
    SentrySDK.capture(error: nsError) { scope in
      scope.setTag(value: "collaboration_invitation", key: "feature")
      scope.setTag(value: stage, key: "invitation_stage")
      scope.setTag(value: nsError.domain, key: "error_domain")
      scope.setTag(value: String(nsError.code), key: "error_code")
      for (key, value) in tags {
        scope.setTag(value: value, key: key)
      }
    }
  }

  private static var configurationName: String {
    #if DEBUG
    "development"
    #else
    "production"
    #endif
  }
}
