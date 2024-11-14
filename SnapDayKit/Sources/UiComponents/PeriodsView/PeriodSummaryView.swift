import SwiftUI

public struct PeriodSummaryView: View {

  private struct PeriodSummaryRow: Identifiable {
    let id: UUID
    let periods: [PeriodSummary]
  }

  private let periodSummaryRows: [PeriodSummaryRow]

  public init(periodSummaryData: PeriodSummaryData) {
    self.periodSummaryRows = periodSummaryData
      .periods
      .chunked(into: periodSummaryData.maxInRow)
      .map {
        PeriodSummaryRow(id: UUID(), periods: $0)
      }
  }

  public var body: some View {
    VStack(spacing: 10.0) {
      ForEach(periodSummaryRows) { row in
        HStack(alignment: .center, spacing: .zero) {
          Spacer()
          ForEach(row.periods) { period in
            VStack(alignment: .center, spacing: 3.0) {
              CircularProgressView(
                progress: period.completedValue,
                lineWidth: 3.0
              )
              .frame(width: 20.0, height: 20.0)

              Text(period.label)
                .font(.system(size: 10.0, weight: .semibold))
                .foregroundStyle(Color.sectionText)
            }

            if period.id != row.periods.last?.id {
              Spacer()
            }
          }
          Spacer()
        }
      }
    }
  }
}
