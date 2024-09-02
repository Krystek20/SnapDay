import Foundation
import ComposableArchitecture
import Models

struct ActivityDatesCreator {

  // MARK: - Dependecies

  @Dependency(\.calendar) private var calendar

  // MARK: - Public

  func createsDates(for activity: Activity, dateRange: ClosedRange<Date>) throws -> [Date] {
    guard activity.isFrequentEnabled else { return [] }
    return switch activity.frequency {
    case .daily:
      createDailyDates(dateRange: dateRange)
    case .weekly(let days):
      try findDates(weekdays: days, order: 1, every: 1, dateRange: dateRange)
    case .biweekly(let days, let startWeek):
      switch startWeek {
      case .current:
        try findDates(weekdays: days, order: 1, every: 2, dateRange: dateRange)
      case .next:
        try findDates(weekdays: days, order: 2, every: 2, dateRange: dateRange)
      }
    case .monthly(let monthlySchedule):
      try findDates(for: monthlySchedule, dateRange: dateRange)
    }
  }

  // MARK: - Private

  private func createDailyDates(dateRange: ClosedRange<Date>) -> [Date] {
    guard let day = calendar.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day else {
      return []
    }
    return (0...day).compactMap {
      calendar.date(byAdding: .day, value: $0, to: dateRange.lowerBound)
    }
  }

  private func findDates(weekdays: [Int], order: Int, every: Int, dateRange: ClosedRange<Date>) throws -> [Date] {
    try weekdays.reduce(into: [Date]()) { result, weekday in
      let dates = try addIf(
        in: dateRange,
        initial: { _ in
          try calendar.weekdayDate(order: order, fromDate: dateRange.lowerBound, weekday: weekday)
        },
        next: { date in
          try calendar.date(byAdding: .weekOfYear, value: every, to: date).unwrapped
        }
      )
      result.append(contentsOf: dates)
    }
  }

  private func findDates(for monthlySchedule: MonthlySchedule, dateRange: ClosedRange<Date>) throws -> [Date] {
    switch monthlySchedule {
    case .firstDay:
      try firstDayDates(in: dateRange)
    case .lastDay:
      try lastDayDates(in: dateRange)
    case .midMonth:
      try midMonthDates(in: dateRange)
    case .monthlySpecificDate(let days):
      try monthlySpecificDates(in: dateRange, days: days)
    case .secondDay:
      try secondDayDates(in: dateRange)
    case .secondToLastDay:
      try secondToLastDayDates(in: dateRange)
    case .weekdayOrdinal(let oridinals):
      try weekdayOrdinalDates(in: dateRange, oridinals: oridinals)
    }
  }

  private func firstDayDates(in dateRange: ClosedRange<Date>) throws -> [Date] {
    try addIf(
      in: dateRange,
      initial: { date in
        try calendar.firstDayOfMonth(fromDate: date)
      },
      next: { date in
        try calendar.date(byAdding: .month, value: 1, to: date).unwrapped
      }
    )
  }

  private func lastDayDates(in dateRange: ClosedRange<Date>) throws -> [Date] {
    try addIf(
      in: dateRange,
      initial: { date in
        try calendar.lastDayOfMonth(fromDate: date)
      },
      next: { date in
        let date = try calendar.date(byAdding: .month, value: 1, to: date).unwrapped
        return try calendar.lastDayOfMonth(fromDate: date)
      }
    )
  }

  private func midMonthDates(in dateRange: ClosedRange<Date>) throws -> [Date] {
    try addIf(
      in: dateRange,
      initial: { date in
        try calendar.midMonth(fromDate: date)
      },
      next: { date in
        try calendar.date(byAdding: .month, value: 1, to: date).unwrapped
      }
    )
  }

  private func monthlySpecificDates(in dateRange: ClosedRange<Date>, days: [Int]) throws -> [Date] {
    try days.reduce(into: [Date]()) { result, day in
      let foundDates = try addIf(
        in: dateRange,
        initial: { date in
          try calendar.findFirstDate(with: day, fromDate: date)
        },
        next: { date in
          let nextMonth = try calendar.nextMonth(fromDate: date)
          return try calendar.findFirstDate(with: day, fromDate: nextMonth)
        }
      )
      result.append(contentsOf: foundDates)
    }
  }

  private func secondDayDates(in dateRange: ClosedRange<Date>) throws -> [Date] {
    try addIf(
      in: dateRange,
      initial: { date in
        try calendar.secondDayOfMonth(fromDate: date)
      },
      next: { date in
        try calendar.date(byAdding: .month, value: 1, to: date).unwrapped
      }
    )
  }

  private func secondToLastDayDates(in dateRange: ClosedRange<Date>) throws -> [Date] {
    try addIf(
      in: dateRange,
      initial: { date in
        try calendar.lastDayOfMonth(fromDate: date, dayOffset: -1)
      },
      next: { date in
        let nextMonth = try calendar.nextMonth(fromDate: date)
        return try calendar.lastDayOfMonth(fromDate: nextMonth, dayOffset: -1)
      }
    )
  }

  private func weekdayOrdinalDates(in dateRange: ClosedRange<Date>, oridinals: [WeekdayOrdinal]) throws -> [Date] {
    try oridinals.reduce(into: [Date]()) { result, oridinal in
      let dates = try oridinal.weekdays.reduce(into: [Date]()) { result, weekday in
        let dates: [Date]
        switch oridinal.position {
        case .first:
          dates = try first(weekday, in: dateRange, offset: 1)
        case .second:
          dates = try first(weekday, in: dateRange, offset: 2)
        case .third:
          dates = try first(weekday, in: dateRange, offset: 3)
        case .fourth:
          dates = try first(weekday, in: dateRange, offset: 4)
        case .secondToLastDay:
          dates = try last(weekday, in: dateRange, offset: -2)
        case .last:
          dates = try last(weekday, in: dateRange, offset: -1)
        }
        result.append(contentsOf: dates)
      }
      result.append(contentsOf: dates)
    }
  }

  private func first(_ weekday: Int, in dateRange: ClosedRange<Date>, offset: Int) throws -> [Date] {
    var firstDayDate = try calendar.firstDayOfMonth(fromDate: dateRange.lowerBound)
    return try addIf(in: dateRange) {
      let firstWeekday = calendar.component(.weekday, from: firstDayDate)

      let inPast = weekday < firstWeekday
      let diff = weekday - firstWeekday

      var currentDate = try calendar.date(byAdding: .day, value: diff, to: firstDayDate).unwrapped
      if inPast {
        currentDate = try calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate).unwrapped
      }
      currentDate = try calendar.date(byAdding: .weekOfYear, value: offset - 1, to: currentDate).unwrapped

      firstDayDate = try calendar.date(byAdding: .month, value: 1, to: firstDayDate).unwrapped
      return currentDate
    }
  }

  private func last(_ weekday: Int, in dateRange: ClosedRange<Date>, offset: Int) throws -> [Date] {
    var lastDayDate = try calendar.lastDayOfMonth(fromDate: dateRange.lowerBound)
    return try addIf(in: dateRange) {
      let lastWeekday = calendar.component(.weekday, from: lastDayDate)

      let inPast = weekday > lastWeekday
      let diff = weekday - lastWeekday

      var currentDate = try calendar.date(byAdding: .day, value: diff, to: lastDayDate).unwrapped
      if inPast {
        currentDate = try calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate).unwrapped
      }
      currentDate = try calendar.date(byAdding: .weekOfYear, value: offset + 1, to: currentDate).unwrapped

      lastDayDate = try calendar.lastDayOfMonth(fromDate: lastDayDate, monthOffset: 1)
      return currentDate
    }
  }

  private func addIf(
    in dateRange: ClosedRange<Date>,
    initial: (Date) throws -> Date,
    next: (Date) throws -> Date
  ) throws -> [Date] {
    var currentDate = try initial(dateRange.lowerBound)
    var dates = [Date]()
    while currentDate <= dateRange.upperBound {
      if dateRange.contains(currentDate) {
        dates.append(currentDate)
      }
      currentDate = try next(currentDate)
    }
    return dates
  }

  private func addIf(in dateRange: ClosedRange<Date>, next: () throws -> Date) throws -> [Date] {
    var currentDate = try next()
    var dates = [Date]()
    while currentDate <= dateRange.upperBound {
      if dateRange.contains(currentDate) {
        dates.append(currentDate)
      }
      currentDate = try next()
    }
    return dates
  }
}
