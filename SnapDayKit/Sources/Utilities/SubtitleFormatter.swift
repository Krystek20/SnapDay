import Foundation

public struct SubtitleFormatter {
  public static func format(
    overview: String? = nil,
    duration: Int? = nil,
  ) -> String {
    var subtitle = ""

    if let duration,
       let formatted = DateComponentsFormatter.duration(for: .minutes(duration)) {
      subtitle += formatted
    }

    if let overview, !overview.isEmpty {
      subtitle += subtitle.isEmpty ? "" : " - "
      subtitle += overview
    }

    return subtitle
  }
}
