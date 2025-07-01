import SwiftUI
import Models

public struct ReportDaysView: View {

  // MARK: - Properties

  private let reportDaysSections: [ReportDaysSection]
  private let columns = Array(repeating: GridItem(), count: 7)

  // MARK: - Initialization

  public init(reportDaysSections: [ReportDaysSection]) {
    self.reportDaysSections = reportDaysSections
  }

  // MARK: - Views

  public var body: some View {
    reportDaysSectionView
  }

  private var reportDaysSectionView: some View {
    LazyVStack(spacing: 20.0) {
      ForEach(reportDaysSections) { section in
        VStack(alignment: .leading, spacing: 5.0) {
          if let title = section.title {
            HStack(spacing: 10.0) {
              Text(title)
                .font(.system(size: 14.0, weight: .medium))
                .foregroundStyle(Color.standardText)
              Rectangle()
                .fill(Color.standardText.opacity(0.1))
                .frame(height: 1.0)
            }
          }
          reportDaysView(reportDays: section.items)
        }
      }
    }
  }

  private func reportDaysView(reportDays: [ReportDay]) -> some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(reportDays) { item in
        VStack(spacing: 2.0) {
          reportDayActivityView(item)
            .frame(height: 30.0)
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
          if let title = item.title {
            Text(title)
              .font(.system(size: 10.0, weight: .medium))
              .foregroundStyle(Color.standardText)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func reportDayActivityView(_ reportDay: ReportDay) -> some View {
    switch reportDay.dayActivity {
    case .tag(let state, let rgbColor):
      switch state {
      case .done:
        rgbColor
          .color
          .frame(width: 18.0, height: 18.0)
          .clipShape(RoundedRectangle(cornerRadius: 9.0))
      case .notDone:
        Image(systemName: "xmark.circle")
          .foregroundStyle(Color.sunburstOrange)
      case .planned:
        rgbColor
          .color
          .frame(width: 18.0, height: 18.0)
          .clipShape(RoundedRectangle(cornerRadius: 9.0))
          .opacity(0.4)
      case .notPlanned:
        Image(systemName: "slash.circle")
          .foregroundStyle(Color.selection)
      }
    case .activity(let state, let iconId):
      switch state {
      case .done:
        ImageView(type: .iconId(iconId), size: 30.0, cornerRadius: 15.0)
      case .notDone:
        Image(systemName: "xmark.circle")
          .foregroundStyle(Color.sunburstOrange)
      case .planned:
        ImageView(type: .iconId(iconId), size: 30.0, cornerRadius: 15.0)
          .opacity(0.4)
      case .notPlanned:
        Image(systemName: "slash.circle")
          .foregroundStyle(Color.selection)
      }
    case .empty:
      Color.clear
    }
  }
}
