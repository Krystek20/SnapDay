import Foundation

public struct ReportDaysSection: Equatable, Identifiable {
  public let id: String
  let title: String?
  let items: [ReportDay]
}
