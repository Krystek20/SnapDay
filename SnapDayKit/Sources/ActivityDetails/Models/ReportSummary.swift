struct ReportSummary: Equatable {
  let doneCount: Int
  let notDoneCount: Int
  let duration: Int

  static let zero = ReportSummary(doneCount: .zero, notDoneCount: .zero, duration: .zero)
}
