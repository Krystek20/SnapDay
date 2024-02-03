import SwiftUI
import Resources
import Models

public struct TimePeriodsView: View {

  // MARK: - Properties

  private let timePeriods: [TimePeriod]
  private let timePeriodTapped: (TimePeriod) -> Void
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(timePeriods: [TimePeriod], timePeriodTapped: @escaping (TimePeriod) -> Void) {
    self.timePeriods = timePeriods
    self.timePeriodTapped = timePeriodTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVGrid(columns: columns, spacing: 15.0) {
      ForEach(timePeriods, content: timePeriodView)
    }
  }

  private func timePeriodView(_ timePeriod: TimePeriod) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(name(for: timePeriod))
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
      ProgressView(value: timePeriod.completedValue) {
        Text("\(timePeriod.percent)%")
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
    }
    .formBackgroundModifier
    .onTapGesture {
      timePeriodTapped(timePeriod)
    }
  }

  // MARK: - Private

  private func name(for timePeriod: TimePeriod) -> String {
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
