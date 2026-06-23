import Foundation

extension ISO8601DateFormatter {
  public static func date(
    from string: String?,
    timeZone: TimeZone = TimeZone(secondsFromGMT: .zero) ?? .current
  ) -> Date? {
    guard let string else {
      print("❌ Empty String")
      return nil
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = timeZone

    return formatter.date(from: string)
  }
}
