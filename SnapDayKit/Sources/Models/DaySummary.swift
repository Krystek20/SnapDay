public struct DaySummary {

  // MARK: - Properties

  private let day: Day

  // MARK: - Initialization

  public init(day: Day) {
    self.day = day
  }

  // MARK: - Public

  public var duration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      result += dayActivity.duration
    })
  }

  public var remaingDuration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      guard !dayActivity.isDone else { return }
      result += dayActivity.duration
    })
  }
//
//  public var summaryRows: [SummaryRow] {
//    day.activities
//      .sortedByName
//      .reduce(into: [SummaryRow](), applySummaryRow)
//  }
//
//  private func applySummaryRow(result: inout [SummaryRow], dayActivity: DayActivity) {
//    for tag in dayActivity.activity.tags {
//      if let summaryRowIndex = result.firstIndex(where: { $0.tag == tag }) {
//        result[summaryRowIndex] = SummaryRow(
//          tag: tag,
//          duration: result[summaryRowIndex].duration + dayActivity.duration
//        )
//      } else {
//        result.append(
//          SummaryRow(
//            tag: tag,
//            duration: dayActivity.duration
//          )
//        )
//      }
//    }
//  }
}
