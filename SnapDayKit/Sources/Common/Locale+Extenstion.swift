import Foundation

extension Locale {
  public static var preferred: Locale {
    guard let preferredLanguage = Locale.preferredLanguages.first else {
      return .autoupdatingCurrent
    }
    return Locale(identifier: preferredLanguage)
  }
}
