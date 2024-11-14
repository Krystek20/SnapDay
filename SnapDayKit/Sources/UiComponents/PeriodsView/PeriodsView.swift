import SwiftUI
import Resources
import Models
import Utilities

public struct PeriodsView: View {

  private let periodSummaryData: PeriodSummaryData
  @State private var columnSize: CGSize = .zero
  @State private var viewSize: CGSize = .zero
  private let columnChartSize = CGSize(width: 35.0, height: 100.0)

  private var optimalHeight: CGFloat {
    CGFloat(periodSummaryData.optimalTime) / CGFloat(periodSummaryData.totalAvailableTimeAvarage) * columnChartSize.height
  }

  private var averageCompletedHeight: CGFloat {
    periodSummaryData.totalCompletedTimePercent * periodSummaryData.totalPlannedTimePercent * columnChartSize.height
  }

  // MARK: - Initialization

  public init(periodSummaryData: PeriodSummaryData) {
    self.periodSummaryData = periodSummaryData
  }

  // MARK: - Views


  public var body: some View {
    ZStack(alignment: .top) {
      if periodSummaryData.isScrollable {
        scrollableContent
          .padding(.horizontal, 15.0)
      } else {
        content
      }

      optimalLine
      optimalPoint
      completedPercentLine
      completedPercentPoint
    }
    .extractSize(in: $viewSize)
  }

  private var scrollableContent: some View {
    ScrollView(.horizontal) {
      content
    }
    .scrollIndicators(.hidden)
  }

  private var content: some View {
    HStack(alignment: .bottom, spacing: 10.0) {
      ForEach(periodSummaryData.periods) { period in
        VStack(alignment: .center, spacing: 5.0) {
          ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5)
              .fill(Color.gray.opacity(0.1))
              .frame(width: columnChartSize.width, height: columnChartSize.height)

            RoundedRectangle(cornerRadius: 5.0)
              .fill(Color.actionBlueLight)
              .frame(width: columnChartSize.width, height: CGFloat(period.totalPlannedDuration) / CGFloat(period.totalAvailableTime) * columnChartSize.height)

            RoundedRectangle(cornerRadius: 5.0)
              .fill(Color.actionBlue)
              .frame(width: columnChartSize.width, height: CGFloat(period.totalCompletedDuration) / CGFloat(period.totalAvailableTime) * columnChartSize.height)
          }
          .extractSize(in: $columnSize)

          Text(period.label)
            .font(.system(size: 10.0, weight: .semibold))
            .foregroundStyle(Color.sectionText)
        }
      }
    }
  }

  private var optimalLine: some View {
    Path { path in
      path.move(to: CGPoint(x: .zero, y: columnSize.height - optimalHeight))
      path.addLine(to: CGPoint(x: viewSize.width, y: columnSize.height - optimalHeight))
    }
    .stroke(Color.sectionText, style: StrokeStyle(lineWidth: 1, dash: [5]))
  }

  private var optimalPoint: some View {
    Circle()
      .frame(width: 8.0, height: 8.0)
      .foregroundColor(Color.sectionText)
      .offset(x: -viewSize.width / 2.0 + 4.0, y: columnSize.height - optimalHeight - 4.0)
  }

  private var completedPercentLine: some View {
    Path { path in
      path.move(to: CGPoint(x: .zero, y: columnSize.height - averageCompletedHeight))
      path.addLine(to: CGPoint(x: viewSize.width, y: columnSize.height - averageCompletedHeight))
    }
    .stroke(Color.greenSuccess, style: StrokeStyle(lineWidth: 1, dash: [5]))
  }

  private var completedPercentPoint: some View {
    Circle()
      .frame(width: 8.0, height: 8.0)
      .foregroundColor(Color.greenSuccess)
      .offset(x: -viewSize.width / 2.0 + 4.0, y: columnSize.height - averageCompletedHeight - 4.0)
  }
}
