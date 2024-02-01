import Foundation

public struct TimeProvider {
  public static func duration(from seconds: Int, bundle: Bundle) -> String? {
    guard seconds > .zero else { return nil }
    let minutes = seconds % 60
    let hours = seconds / 60
    return String(localized: "\(hours)h \(minutes)min", bundle: bundle)
  }
}
