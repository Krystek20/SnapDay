import Foundation

extension Calendar {
  public func dayFormat(_ fromDate: Date) -> Date {
    let components = dateComponents([.year, .month, .day], from: fromDate)
    return date(from: components) ?? fromDate
  }

  public func monthName(_ fromDate: Date) throws -> String {
    let dateFormatter = DateFormatter()
    guard let month = dateComponents([.month], from: fromDate).month,
          dateFormatter.standaloneMonthSymbols.indices.contains(month - 1) else {
      throw DateError.monthNotExist
    }
    return dateFormatter.standaloneMonthSymbols[month - 1]
  }

  public func currentDateRange(_ fromDate: Date) -> ClosedRange<Date> {
    var components = dateComponents([.year, .month, .day], from: fromDate)
    components.hour = 0
    components.minute = 0
    let startDate = date(from: components) ?? fromDate
    components.hour = 23
    components.minute = 59
    let endDate = date(from: components) ?? fromDate
    return startDate...endDate
  }

  public func setHourAndMinute(_ fromDate: Date, toDate: Date) -> Date? {
    let currentHour = component(.hour, from: fromDate)
    let currentMinute = component(.minute, from: fromDate)
    var dateComponents = dateComponents([.year, .month, .day], from: toDate)
    dateComponents.hour = currentHour
    dateComponents.minute = currentMinute
    return date(from: dateComponents)
  }
}

extension Calendar {
  func weekdayDate(order: Int, fromDate: Date, weekday: Int) throws -> Date {
    let currentWeekday = component(.weekday, from: fromDate)
    let weekdayDifference = (weekday - currentWeekday + 7) % 7

    var dateComponents = DateComponents()
    dateComponents.day = weekdayDifference + (order - 1) * 7

    return try date(byAdding: dateComponents, to: fromDate).unwrapped
  }

  func firstDayOfMonth(fromDate: Date) throws -> Date {
    try date(with: 1, fromDate: fromDate)
  }

  func secondDayOfMonth(fromDate: Date) throws -> Date {
    try date(with: 2, fromDate: fromDate)
  }

  func midMonth(fromDate: Date) throws -> Date {
    try date(with: 15, fromDate: fromDate)
  }

  func lastDayOfMonth(fromDate: Date, dayOffset: Int = .zero, monthOffset: Int = .zero) throws -> Date {
    let components = DateComponents(
      year: component(.year, from: fromDate),
      month: component(.month, from: fromDate) + 1 + monthOffset,
      day: .zero
    )
    let lastDay = try date(from: components).unwrapped
    return try date(byAdding: .day, value: dayOffset, to: lastDay).unwrapped
  }

  func findFirstDate(with day: Int, fromDate: Date) throws -> Date {
    var dateToFind = fromDate
    while range(of: .day, in: .month, for: dateToFind)?.contains(day) != true {
      dateToFind = try firstDayOfMonth(fromDate: dateToFind)
      dateToFind = try date(byAdding: .month, value: 1, to: dateToFind).unwrapped
    }
    return try date(with: day, fromDate: dateToFind)
  }

  func nextMonth(fromDate: Date) throws -> Date {
    let currentMonth = try firstDayOfMonth(fromDate: fromDate)
    return try date(byAdding: .month, value: 1, to: currentMonth).unwrapped
  }

  func daysNumber(in dateRange: ClosedRange<Date>) -> Int? {
    dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day
  }

  private func date(with day: Int?, fromDate: Date) throws -> Date {
    let components = DateComponents(
      year: component(.year, from: fromDate),
      month: component(.month, from: fromDate),
      day: day
    )
    return try date(from: components).unwrapped
  }
}
