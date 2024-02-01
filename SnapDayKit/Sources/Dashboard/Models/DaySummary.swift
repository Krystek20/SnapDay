import Models

struct DaySummary {
  let day: Day
  
  var duration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      result += dayActivity.duration
    })
  }

  var remaingDuration: Int {
    day.activities.reduce(into: Int.zero, { result, dayActivity in
      guard !dayActivity.isDone else { return }
      result += dayActivity.duration
    })
  }

  struct SummaryRow: Identifiable {
    var id: Tag { tag }
    let tag: Tag
    var duration: Int
  }

  var summaryRows: [SummaryRow] {
    day.activities
      .sortedByName
      .reduce(into: [SummaryRow](), applySummaryRow)
  }

  private func applySummaryRow(result: inout [SummaryRow], dayActivity: DayActivity) {
    for tag in dayActivity.activity.tags {
      if let summaryRowIndex = result.firstIndex(where: { $0.tag == tag }) {
        result[summaryRowIndex] = SummaryRow(
          tag: tag,
          duration: result[summaryRowIndex].duration + dayActivity.duration
        )
      } else {
        result.append(
          SummaryRow(
            tag: tag,
            duration: dayActivity.duration
          )
        )
      }
    }
  }
}
