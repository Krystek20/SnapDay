public struct SubtitleFormatter {
  public static func format(
    overview: String? = nil,
    duration: Int? = nil,
  ) -> String {
    var subtitle = ""

    if let duration, let formatted = formattedDuration(duration: duration) {
      subtitle += formatted
    }

    if let overview, !overview.isEmpty {
      subtitle += subtitle.isEmpty ? "" : " - "
      subtitle += overview
    }

    return subtitle
  }

  private static func formattedDuration(duration: Int) -> String? {
    guard duration > .zero else { return nil }
    let minutes = duration % 60
    let hours = duration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }
}
