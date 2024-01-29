import Foundation

enum DateError: Error {
  case dateNotExist
}

extension Date? {
  var unwrapped: Date {
    get throws {
      guard let date = self else { throw DateError.dateNotExist }
      return date
    }
  }
}
