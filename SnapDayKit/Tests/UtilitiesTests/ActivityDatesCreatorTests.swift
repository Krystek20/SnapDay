import XCTest
import Models
import ComposableArchitecture
@testable import Utilities

final class ActivityDatesCreatorTest: XCTestCase {

  // MARK: - Properties

  private var sut: ActivityDatesCreator!
  private let calendar = Calendar.autoupdatingCurrent
  private var quarter: ClosedRange<Date>!

  // MARK: - Setup

  override func setUpWithError() throws {
    try super.setUpWithError()
    quarter = try prepareRange(
      lowerBound: DateComponents(year: 2023, month: 10, day: 1),
      upperBound: DateComponents(year: 2023, month: 12, day: 31)
    )
    sut = withDependencies {
      $0.calendar = calendar
    } operation: {
      ActivityDatesCreator()
    }
  }

  override func tearDown() {
    super.tearDown()
    sut = nil
  }

  // MARK: - Tests

  func testDaily() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .daily)
    let days = try XCTUnwrap(calendar.dateComponents([.day], from: quarter.lowerBound, to: quarter.upperBound).day)
    let expected = (0...days).compactMap { day in
      calendar.date(byAdding: .day, value: day, to: quarter.lowerBound)
    }

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testWeekly() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .weekly(days: [1, 3, 5, 7]))
    let sundays = try everyWeek(from: 1, weekCount: 14)
    let tuesdays = try everyWeek(from: 3, weekCount: 13)
    let thursdays = try everyWeek(from: 5, weekCount: 13)
    let saturdays = try everyWeek(from: 7, weekCount: 13)
    let expected = sundays + tuesdays + thursdays + saturdays

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testWeeklyBiweeklyCurrent() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .biweekly(days: [1, 3, 5, 7], startWeek: .current))
    let sundays = try everyTwoWeeks(from: 1, weekCount: 7, startWeek: .current)
    let tuesdays = try everyTwoWeeks(from: 3, weekCount: 7, startWeek: .current)
    let thursdays = try everyTwoWeeks(from: 5, weekCount: 7, startWeek: .current)
    let saturdays = try everyTwoWeeks(from: 7, weekCount: 7, startWeek: .current)
    let expected = sundays + tuesdays + thursdays + saturdays

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testWeeklyBiweeklyNext() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .biweekly(days: [1, 3, 5, 7], startWeek: .next))
    let sundays = try everyTwoWeeks(from: 1, weekCount: 7, startWeek: .next)
    let tuesdays = try everyTwoWeeks(from: 3, weekCount: 6, startWeek: .next)
    let thursdays = try everyTwoWeeks(from: 5, weekCount: 6, startWeek: .next)
    let saturdays = try everyTwoWeeks(from: 7, weekCount: 6, startWeek: .next)
    let expected = sundays + tuesdays + thursdays + saturdays

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyFirstDay() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .firstDay))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 1)),
      try date(from: DateComponents(year: 2023, month: 11, day: 1)),
      try date(from: DateComponents(year: 2023, month: 12, day: 1))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyLastDay() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .lastDay))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 31)),
      try date(from: DateComponents(year: 2023, month: 11, day: 30)),
      try date(from: DateComponents(year: 2023, month: 12, day: 31))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyMidMonth() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .midMonth))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 15)),
      try date(from: DateComponents(year: 2023, month: 11, day: 15)),
      try date(from: DateComponents(year: 2023, month: 12, day: 15))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlySecondDay() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .secondDay))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 2)),
      try date(from: DateComponents(year: 2023, month: 11, day: 2)),
      try date(from: DateComponents(year: 2023, month: 12, day: 2))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyMonthlySpecificDate() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .monthlySpecificDate([1, 15, 31])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 1)),
      try date(from: DateComponents(year: 2023, month: 11, day: 1)),
      try date(from: DateComponents(year: 2023, month: 12, day: 1)),
      try date(from: DateComponents(year: 2023, month: 10, day: 15)),
      try date(from: DateComponents(year: 2023, month: 11, day: 15)),
      try date(from: DateComponents(year: 2023, month: 12, day: 15)),
      try date(from: DateComponents(year: 2023, month: 10, day: 31)),
      try date(from: DateComponents(year: 2023, month: 12, day: 31)),
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlySecondToLastDay() throws {
    // given
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .secondToLastDay))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 30)),
      try date(from: DateComponents(year: 2023, month: 11, day: 29)),
      try date(from: DateComponents(year: 2023, month: 12, day: 30))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyWeekdayOrdinalFirst() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .first, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 1)),
      try date(from: DateComponents(year: 2023, month: 11, day: 5)),
      try date(from: DateComponents(year: 2023, month: 12, day: 3)),
      try date(from: DateComponents(year: 2023, month: 10, day: 4)),
      try date(from: DateComponents(year: 2023, month: 11, day: 1)),
      try date(from: DateComponents(year: 2023, month: 12, day: 6)),
      try date(from: DateComponents(year: 2023, month: 10, day: 7)),
      try date(from: DateComponents(year: 2023, month: 11, day: 4)),
      try date(from: DateComponents(year: 2023, month: 12, day: 2))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyWeekdayOrdinalSecond() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .second, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 8)),
      try date(from: DateComponents(year: 2023, month: 11, day: 12)),
      try date(from: DateComponents(year: 2023, month: 12, day: 10)),
      try date(from: DateComponents(year: 2023, month: 10, day: 11)),
      try date(from: DateComponents(year: 2023, month: 11, day: 8)),
      try date(from: DateComponents(year: 2023, month: 12, day: 13)),
      try date(from: DateComponents(year: 2023, month: 10, day: 14)),
      try date(from: DateComponents(year: 2023, month: 11, day: 11)),
      try date(from: DateComponents(year: 2023, month: 12, day: 9))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }
  
  func testMonthlyWeekdayOrdinalThird() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .third, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 15)),
      try date(from: DateComponents(year: 2023, month: 11, day: 19)),
      try date(from: DateComponents(year: 2023, month: 12, day: 17)),
      try date(from: DateComponents(year: 2023, month: 10, day: 18)),
      try date(from: DateComponents(year: 2023, month: 11, day: 15)),
      try date(from: DateComponents(year: 2023, month: 12, day: 20)),
      try date(from: DateComponents(year: 2023, month: 10, day: 21)),
      try date(from: DateComponents(year: 2023, month: 11, day: 18)),
      try date(from: DateComponents(year: 2023, month: 12, day: 16))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyWeekdayOrdinalFourth() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .fourth, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 22)),
      try date(from: DateComponents(year: 2023, month: 11, day: 26)),
      try date(from: DateComponents(year: 2023, month: 12, day: 24)),
      try date(from: DateComponents(year: 2023, month: 10, day: 25)),
      try date(from: DateComponents(year: 2023, month: 11, day: 22)),
      try date(from: DateComponents(year: 2023, month: 12, day: 27)),
      try date(from: DateComponents(year: 2023, month: 10, day: 28)),
      try date(from: DateComponents(year: 2023, month: 11, day: 25)),
      try date(from: DateComponents(year: 2023, month: 12, day: 23))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyWeekdayOrdinalSecondToLastDay() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .secondToLastDay, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 22)),
      try date(from: DateComponents(year: 2023, month: 11, day: 19)),
      try date(from: DateComponents(year: 2023, month: 12, day: 24)),
      try date(from: DateComponents(year: 2023, month: 10, day: 18)),
      try date(from: DateComponents(year: 2023, month: 11, day: 22)),
      try date(from: DateComponents(year: 2023, month: 12, day: 20)),
      try date(from: DateComponents(year: 2023, month: 10, day: 21)),
      try date(from: DateComponents(year: 2023, month: 11, day: 18)),
      try date(from: DateComponents(year: 2023, month: 12, day: 23))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  func testMonthlyWeekdayOrdinalLast() throws {
    // given
    let weekdayOrdinal = WeekdayOrdinal(position: .last, weekdays: [1, 4, 7])
    let activity = Activity(id: UUID(1), name: "name", frequency: .monthly(monthlySchedule: .weekdayOrdinal([weekdayOrdinal])))
    let expected = [
      try date(from: DateComponents(year: 2023, month: 10, day: 29)),
      try date(from: DateComponents(year: 2023, month: 11, day: 26)),
      try date(from: DateComponents(year: 2023, month: 12, day: 31)),
      try date(from: DateComponents(year: 2023, month: 10, day: 25)),
      try date(from: DateComponents(year: 2023, month: 11, day: 29)),
      try date(from: DateComponents(year: 2023, month: 12, day: 27)),
      try date(from: DateComponents(year: 2023, month: 10, day: 28)),
      try date(from: DateComponents(year: 2023, month: 11, day: 25)),
      try date(from: DateComponents(year: 2023, month: 12, day: 30))
    ]

    // when
    let dates = try sut.createsDates(for: activity, dateRange: quarter)

    // then
    XCTAssertEqual(dates, expected)
  }

  // MARK: - Helpers

  private func prepareRange(lowerBound: DateComponents, upperBound: DateComponents) throws -> ClosedRange<Date> {
    try date(from: lowerBound)...date(from: upperBound)
  }

  private func date(from dateComponents: DateComponents) throws -> Date {
    try XCTUnwrap(calendar.date(from: dateComponents))
  }

  private func everyWeek(from day: Int, weekCount: Int) throws -> [Date] {
    let date = try date(from: DateComponents(year: 2023, month: 10, day: day))
    return (0..<weekCount).compactMap { week in
      calendar.date(byAdding: .weekOfYear, value: week, to: date)
    }
  }

  private func everyTwoWeeks(from day: Int, weekCount: Int, startWeek: BiweeklyStartWeek) throws -> [Date] {
    let date = try date(from: DateComponents(year: 2023, month: 10, day: day))
    return (0..<weekCount).compactMap { week in
      var value = week * 2
      if startWeek == .next {
        value += 1
      }
      return calendar.date(byAdding: .weekOfYear, value: value, to: date)
    }
  }
}
