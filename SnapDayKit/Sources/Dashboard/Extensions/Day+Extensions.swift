import Models

extension Day {
  var sortedDayActivities: [DayActivity] {
    activities.sorted(by: {
      if $0.isDone == $1.isDone { return $0.activity.name < $1.activity.name }
      return !$0.isDone && $1.isDone
    })
  }
}
