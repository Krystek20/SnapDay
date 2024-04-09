public protocol DefaultDurationProtocol {
  var defaultDuration: Int? { get set }
}

extension DefaultDurationProtocol {
  public var isDefaultDuration: Bool {
    defaultDuration != nil
  }

  public mutating func setDefaultDuration(_ isDefaultDuration: Bool) {
    defaultDuration = isDefaultDuration ? .zero : nil
  }

  public var hours: Int {
    guard let defaultDuration else { return .zero }
    return defaultDuration / 60
  }

  public mutating func setDurationHours(_ hours: Int) {
    guard let duration = defaultDuration else { return }
    if duration == .zero {
      defaultDuration = hours * 60
    } else {
      let minutes = Int(duration % 60)
      defaultDuration = hours * 60 + minutes
    }
  }

  public var minutes: Int {
    guard let defaultDuration else { return .zero }
    return defaultDuration % 60
  }

  public mutating func setDurationMinutes(_ minutes: Int) {
    guard let duration = defaultDuration else { return }
    if duration == .zero {
      defaultDuration = minutes
    } else {
      let hours = Int(duration / 60)
      defaultDuration = hours * 60 + minutes
    }
  }
}
