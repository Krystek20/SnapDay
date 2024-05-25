import Foundation

protocol DurationFormatting {
  func duration(for duration: Int) -> String?
}

extension DurationFormatting {
  func duration(for duration: Int) -> String? {
    guard duration > .zero else { return nil }
    let minutes = duration % 60
    let hours = duration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }
}
