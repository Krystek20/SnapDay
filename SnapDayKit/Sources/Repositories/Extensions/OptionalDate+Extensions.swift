import Foundation

public extension Optional where Wrapped == Date {
  var orPast: Date {
    self ?? .distantPast
  }
}
