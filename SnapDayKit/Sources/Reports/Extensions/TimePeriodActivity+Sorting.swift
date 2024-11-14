import Models

extension [TimePeriodActivity] {
  func sortedByPriority() -> [TimePeriodActivity] {
    sorted(by: {
      if $0.isImportant != $1.isImportant {
        return $0.isImportant && !$1.isImportant
      }

      if $0.showProgress && $0.percent == .zero {
        return false
      }
      if $1.showProgress && $1.percent == .zero {
        return true
      }

      if $0.showProgress != $1.showProgress {
        return $0.showProgress && !$1.showProgress
      }

      if $0.duration != $1.duration {
        return $0.duration > $1.duration
      }

      if $0.percent != $1.percent {
          return $0.percent > $1.percent
      }

      return $0.doneCount > $1.doneCount
    })
  }
}
