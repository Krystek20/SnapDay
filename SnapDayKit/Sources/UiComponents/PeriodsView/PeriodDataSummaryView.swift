import SwiftUI
import Utilities

public struct PeriodDataSummaryView: View {

  private let periodSummaryData: PeriodSummaryData

  public init(periodSummaryData: PeriodSummaryData) {
    self.periodSummaryData = periodSummaryData
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      if let remaingDuration = DateComponentsFormatter.duration(for: .minutes(periodSummaryData.totalAvailableTime)) {
        HStack(alignment: .center,spacing: 2.5) {
          RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 10.0, height: 10.0)
          Text("Total Available Time", bundle: .module)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.standardText)
          Spacer()
          Text(remaingDuration)
            .font(.system(size: 12.0, weight: .semibold))
            .foregroundStyle(Color.standardText)
        }
      }
      if let totalPlannedTime = DateComponentsFormatter.duration(for: .minutes(periodSummaryData.totalPlannedTime)) {
        HStack(alignment: .center,spacing: 2.5) {
          RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.actionBlueLight)
            .frame(width: 10.0, height: 10.0)
          Text("Total Planned Time", bundle: .module)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.standardText)
          Spacer()
          Text(totalPlannedTime)
            .font(.system(size: 12.0, weight: .semibold))
            .foregroundStyle(Color.standardText)
          Text("(\(Int(periodSummaryData.totalPlannedTimePercent * 100))%)")
            .font(.system(size: 10.0, weight: .bold))
            .foregroundStyle(Color.standardText)
        }
      }
      if let totalCompletedTime = DateComponentsFormatter.duration(for: .minutes(periodSummaryData.totalCompletedTime)) {
        HStack(alignment: .center, spacing: 2.5) {
          RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.actionBlue)
            .frame(width: 10.0, height: 10.0)
          Text("Total Completed Time", bundle: .module)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.standardText)
          Spacer()
          Text(totalCompletedTime)
            .font(.system(size: 12.0, weight: .semibold))
            .foregroundStyle(Color.standardText)
          Text("(\(Int(periodSummaryData.totalCompletedTimePercent * 100))%)")
            .font(.system(size: 10.0, weight: .bold))
            .foregroundStyle(Color.standardText)
        }
      }
    }
  }
}
