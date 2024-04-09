import Foundation

public protocol DurationProtocol {
  var duration: Int { get set }
}

extension DurationProtocol {
  public var minutes: Int {
    duration % 60
  }

  public mutating func setDurationMinutes(_ minutes: Int) {
    if duration == .zero {
      duration = minutes
    } else {
      let hours = Int(duration / 60)
      duration = hours * 60 + minutes
    }
  }

  public var hours: Int {
    duration / 60
  }

  public mutating func setDurationHours(_ hours: Int) {
    if duration == .zero {
      duration = hours * 60
    } else {
      let minutes = Int(duration % 60)
      duration = hours * 60 + minutes
    }
  }
}
