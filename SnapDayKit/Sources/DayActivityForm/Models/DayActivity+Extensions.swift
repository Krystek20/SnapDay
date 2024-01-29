import Models

extension DayActivity {
  var minutes: Int {
    duration % 60
  }

  mutating func setDurationMinutes(_ minutes: Int) {
    if duration == .zero {
      duration = minutes
    } else {
      let hours = Int(duration / 60)
      duration = hours * 60 + minutes
    }
  }

  var hours: Int {
    duration / 60
  }

  mutating func setDurationHours(_ hours: Int) {
    if duration == .zero {
      duration = hours * 60
    } else {
      let minutes = Int(duration % 60)
      duration = hours * 60 + minutes
    }
  }
}
