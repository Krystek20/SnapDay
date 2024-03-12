import SwiftUI
import Resources
import Models

public struct TimePeriodsView: View {

  // MARK: - Properties

  private let timePeriods: [TimePeriod]
  private let timePeriodTapped: (TimePeriod) -> Void

  // MARK: - Initialization

  public init(
    timePeriods: [TimePeriod],
    timePeriodTapped: @escaping (TimePeriod) -> Void
  ) {
    self.timePeriods = timePeriods
    self.timePeriodTapped = timePeriodTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(spacing: .zero) {
      ForEach(timePeriods) { timePeriod in
        VStack(spacing: .zero) {
          timePeriodView(timePeriod)
          if timePeriod.id != timePeriods.last?.id {
            Divider()
          }
        }
      }
    }
  }

  private func timePeriodView(_ timePeriod: TimePeriod) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(name(for: timePeriod))
        .font(.system(size: 14.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
      ProgressView(value: timePeriod.completedValue) {
        Text("\(timePeriod.percent)%")
          .font(.system(size: 14.0, weight: .semibold))
          .foregroundStyle(Color.standardText)
      }
    }
    .formBackgroundModifier()
    .onTapGesture {
      timePeriodTapped(timePeriod)
    }
  }

  // MARK: - Private

  private func name(for timePeriod: TimePeriod) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM yyyy"
    let startDate = formatter.string(from: timePeriod.dateRange.lowerBound)
    let endDate = formatter.string(from: timePeriod.dateRange.upperBound)
    return String(format: "%@ - %@", startDate, endDate)
  }
}
