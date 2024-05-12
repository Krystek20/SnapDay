import SwiftUI
import Resources
import Models

public struct ActivitiesByTagView: View {

  // MARK: - Properties

  private let tagActivitySection: TagActivitySection
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(tagActivitySection: TagActivitySection) {
    self.tagActivitySection = tagActivitySection
  }

  // MARK: - Views

  public var body: some View {
      activityDetailsSectionView
  }

  private var activityDetailsSectionView: some View {
    LazyVStack(spacing: 10.0) {
      ForEach(tagActivitySection.timePeriodActivities) { timePeriodActivity in
        VStack(spacing: 10.0) {
          activityDetailsView(timePeriodActivity)
          if timePeriodActivity.id != tagActivitySection.timePeriodActivities.last?.id {
            Divider()
          }
        }
      }
    }
  }

  private func activityDetailsView(_ timePeriodActivity: TimePeriodActivity) -> some View {
    VStack(alignment: .leading, spacing: 5.0) {
      ActivitySummaryRow(
        activityType: .activity(timePeriodActivity.activity),
        durationType: .custom(timePeriodActivity.duration)
      )

      if timePeriodActivity.activity.isRepeatable {
        ProgressView(value: timePeriodActivity.completedValue) {
          HStack(alignment: .bottom) {
            Text("\(timePeriodActivity.percent)%", bundle: .module)
              .font(.system(size: 14.0, weight: .medium))
              .foregroundStyle(Color.standardText)
            Spacer()
            Text("\(timePeriodActivity.doneCount) / \(timePeriodActivity.totalCount)", bundle: .module)
              .font(.system(size: 12.0, weight: .medium))
              .foregroundStyle(Color.sectionText)
          }
        }
        .tint(.actionBlue)
      } else {
        Text("Total: \(timePeriodActivity.doneCount)", bundle: .module)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.standardText)
      }
    }
  }
}
