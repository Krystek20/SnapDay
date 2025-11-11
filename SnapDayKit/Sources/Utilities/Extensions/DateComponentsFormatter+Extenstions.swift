import Foundation
import Common

public extension DateComponentsFormatter {

  enum Unit {
    case seconds(Int)
    case minutes(Int)

    fileprivate var duration: TimeInterval {
      switch self {
      case .seconds(let seconds): TimeInterval(seconds)
      case .minutes(let minutes): TimeInterval(minutes * 60)
      }
    }
  }

  static func duration(
    for unit: Unit,
    skipIfZero: Bool = true
  ) -> String? {
    guard unit.duration > .zero || !skipIfZero else { return nil }

    var calendar = Calendar.autoupdatingCurrent
    calendar.locale = .preferred

    let formatter = DateComponentsFormatter()
    formatter.zeroFormattingBehavior = .dropAll
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    formatter.calendar = calendar

    return formatter.string(from: unit.duration)
  }
}
