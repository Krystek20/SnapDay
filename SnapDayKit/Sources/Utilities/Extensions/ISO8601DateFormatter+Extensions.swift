import Foundation

extension ISO8601DateFormatter {
  public static func utcDate(from string: String?) -> Date? {
    guard let string else {
      print("❌ Failed to convert string to date: \(string)")
      return nil
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

    return formatter.date(from: string)
  }
}
