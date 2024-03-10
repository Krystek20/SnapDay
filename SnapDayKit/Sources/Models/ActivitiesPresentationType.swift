import Foundation

public enum DaysSelectorStyle: Equatable {
  case single(day: Day)
  case multi(days: [Day])
}

public enum ActivitiesPresentationType: Equatable {
  case monthsList([TimePeriod])
  case calendar([CalendarItemType])
  case daysList(DaysSelectorStyle)
}
