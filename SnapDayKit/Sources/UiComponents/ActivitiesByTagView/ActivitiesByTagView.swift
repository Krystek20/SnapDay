import SwiftUI
import Resources
import Utilities
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
      HStack(spacing: 5.0) {
        ActivityImageView(
          data: timePeriodActivity.activity.icon?.data,
          size: 30.0,
          cornerRadius: 15.0
        )
        Text(timePeriodActivity.activity.name)
          .font(.system(size: 14.0, weight: .medium))
          .multilineTextAlignment(.leading)
          .foregroundStyle(Color.sectionText)
        Spacer()
        if timePeriodActivity.duration > .zero {
          HStack(spacing: 5.0) {
            Image(systemName: "clock")
              .foregroundStyle(Color.sectionText)
              .imageScale(.small)
            Text(TimeProvider.duration(from: timePeriodActivity.duration, bundle: .module) ?? "")
              .font(.system(size: 12.0, weight: .semibold))
              .foregroundStyle(Color.sectionText)
          }
        }
      }

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
