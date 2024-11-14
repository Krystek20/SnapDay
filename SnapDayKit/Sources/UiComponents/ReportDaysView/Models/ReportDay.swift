struct ReportDay: Equatable, Identifiable {
  let id: String
  let title: String?
  let dayActivity: ReportDayActivity
}
