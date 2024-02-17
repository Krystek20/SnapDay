import SwiftUI
import Utilities
import Models
import Resources

public struct TimeSummaryView: View {

  // MARK: - Properties

  private let daySummary: DaySummary

  // MARK: - Initialization

  public init(daySummary: DaySummary) {
    self.daySummary = daySummary
  }

  // MARK: - Views

  public var body: some View {
    LazyVStack(alignment: .leading, spacing: 10.0) {
      ForEach(daySummary.summaryRows) { summaryRow in
        HStack(spacing: 5.0) {
          TagView(tag: summaryRow.tag)
          Spacer()
          Text(TimeProvider.duration(from: summaryRow.duration, bundle: .module) ?? "")
            .font(Fonts.Quicksand.regular.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.slateHaze.swiftUIColor)
        }
      }
      Divider()
      VStack(spacing: 10.0) {
        HStack(spacing: 5.0) {
          Text("Remaining Time", bundle: .module)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
            .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
          Spacer()
          Text(TimeProvider.duration(from: daySummary.remaingDuration, bundle: .module) ?? "")
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
        }
        HStack(spacing: 5.0) {
          Text("Total Task Time", bundle: .module)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
            .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
          Spacer()
          Text(TimeProvider.duration(from: daySummary.duration, bundle: .module) ?? "")
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
        }
      }
    }
    .maxWidth()
    .formBackgroundModifier()
  }
}
