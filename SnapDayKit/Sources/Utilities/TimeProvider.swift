import Foundation

public struct TimeProvider {
  public static func duration(from seconds: Int, bundle: Bundle) -> String? {
    guard seconds > .zero else { return nil }
    let minutes = seconds % 60
    let hours = seconds / 60
    return if hours > .zero && minutes > .zero {
      String(localized: "\(hours)h \(minutes)min", bundle: bundle)
    } else if hours > .zero && minutes == .zero {
      String(localized: "\(hours)h", bundle: bundle)
    } else if hours == .zero && minutes > .zero {
      String(localized: "\(minutes)min", bundle: bundle)
    } else {
      nil
    }
  }
}
