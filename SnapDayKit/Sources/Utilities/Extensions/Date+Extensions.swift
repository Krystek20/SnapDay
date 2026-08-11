import Foundation
import Common

enum DateError: Error {
  case dateNotExist
  case monthNotExist
}

extension Date? {
  var unwrapped: Date {
    get throws {
      guard let date = self else { throw DateError.dateNotExist }
      return date
    }
  }
}

public extension Date {
  func formatted(
    template: String,
    calendar: Calendar,
    locale: Locale = .preferred
  ) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = locale
    formatter.setLocalizedDateFormatFromTemplate(template)
    return formatter.string(from: self)
  }
}
