import SwiftUI
import Resources
import Models

public enum TimePeriodsViewType {
  case grid
  case list
}

public struct TimePeriodsView: View {

  // MARK: - Properties

  private let timePeriods: [TimePeriod]
  private let timePeriodTapped: (TimePeriod) -> Void
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]
  private let type: TimePeriodsViewType

  // MARK: - Initialization

  public init(
    timePeriods: [TimePeriod],
    type: TimePeriodsViewType,
    timePeriodTapped: @escaping (TimePeriod) -> Void
  ) {
    self.timePeriods = timePeriods
    self.type = type
    self.timePeriodTapped = timePeriodTapped
  }

  // MARK: - Views

  public var body: some View {
    switch type {
    case .grid:
      LazyVGrid(columns: columns, spacing: 15.0) {
        ForEach(timePeriods, content: timePeriodView)
      }
    case .list:
      LazyVStack(spacing: 15.0) {
        ForEach(timePeriods, content: timePeriodView)
      }
    }
  }

  private func timePeriodView(_ timePeriod: TimePeriod) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(name(for: timePeriod))
        .font(.system(size: 16.0, weight: .bold))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
      ProgressView(value: timePeriod.completedValue) {
        Text("\(timePeriod.percent)%")
          .font(.system(size: 14.0, weight: .bold))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
    }
    .formBackgroundModifier()
    .onTapGesture {
      timePeriodTapped(timePeriod)
    }
  }

  // MARK: - Private

  private func name(for timePeriod: TimePeriod) -> String {
    switch type {
    case .grid:
      return periodName(for: timePeriod)
    case .list:
      let formatter = DateFormatter()
      formatter.dateFormat = "d MMM yyyy"
      let startDate = formatter.string(from: timePeriod.dateRange.lowerBound)
      let endDate = formatter.string(from: timePeriod.dateRange.upperBound)
      return String(format: "%@ - %@", startDate, endDate)
    }
  }

  private func periodName(for timePeriod: TimePeriod) -> String {
    switch timePeriod.type {
    case .day:
      String(localized: "Daily", bundle: .module)
    case .week:
      String(localized: "Weekly", bundle: .module)
    case .month:
      String(localized: "Monthly", bundle: .module)
    case .quarter:
      String(localized: "Quarterly", bundle: .module)
    }
  }
}
