import SwiftUI
import Resources
import Models

public struct PeriodsView: View {

  // MARK: - Properties

  private let periods: [PeriodViewModel]

  // MARK: - Initialization

  public init(periods: [PeriodViewModel]) {
    self.periods = periods
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(periods) { period in
        VStack(spacing: .zero) {
          periodView(period)
          if period.id != periods.last?.id {
            Divider()
          }
        }
      }
    }
    .background(
      Color.formBackground
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
    )
  }

  private func periodView(_ period: PeriodViewModel) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(period.label)
        .font(.system(size: 14.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
      ProgressView(value: period.completedValue) {
        Text("\(period.percent)%")
          .font(.system(size: 14.0, weight: .semibold))
          .foregroundStyle(Color.standardText)
      }
    }
    .padding(.all, 10.0)
  }
}
