import SwiftUI
import Resources
import Utilities
import Models

public struct ActivitiesByTagView: View {

  // MARK: - Properties

  private let timePeriodActivitySections: [TimePeriodActivitySection]
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]
  @Binding private var selectedTag: Tag?

  // MARK: - Initialization

  public init(selectedTag: Binding<Tag?>, timePeriodActivitySections: [TimePeriodActivitySection]) {
    self.timePeriodActivitySections = timePeriodActivitySections
    self._selectedTag = selectedTag
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      ScrollView(.horizontal) {
        HStack(spacing: 10.0) {
          ForEach(timePeriodActivitySections.map(\.tag), content: tagView)
        }
      }
      if let timePeriodActivitySection = timePeriodActivitySections.first(where: { $0.tag == selectedTag }) {
        activityDetailsSectionView(timePeriodActivitySection)
      }
    }
  }

  private func tagView(_ tag: Tag) -> some View {
    TagView(tag: tag)
      .opacity(tag == selectedTag ? 1.0 : 0.3)
      .onTapGesture {
        selectedTag = tag
      }
  }

  private func activityDetailsSectionView(_ timePeriodActivitySection: TimePeriodActivitySection) -> some View {
    LazyVGrid(columns: columns, spacing: 15.0) {
      ForEach(timePeriodActivitySection.timePeriodActivities, content: activityDetailsView)
    }
  }

  private func activityDetailsView(_ timePeriodActivity: TimePeriodActivity) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      HStack(spacing: 10.0) {
        ActivityImageView(
          data: timePeriodActivity.activity.image,
          size: 20.0,
          cornerRadius: 10.0
        )
        Text(timePeriodActivity.activity.name)
          .lineLimit(1)
          .font(.system(size: 16.0, weight: .bold))
          .foregroundStyle(Color.slateHaze)
        Spacer()
      }

      if timePeriodActivity.duration > .zero {
        HStack {
          Image(systemName: "clock")
            .foregroundStyle(Color.slateHaze)
            .imageScale(.small)
          Text(TimeProvider.duration(from: timePeriodActivity.duration, bundle: .module) ?? "")
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.slateHaze)
        }
      }

      if timePeriodActivity.activity.isRepeatable {
        ProgressView(value: timePeriodActivity.completedValue) {
          HStack(alignment: .bottom) {
            Text("\(timePeriodActivity.percent)%", bundle: .module)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
            Spacer()
            Text("\(timePeriodActivity.doneCount) / \(timePeriodActivity.totalCount)", bundle: .module)
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.slateHaze)
          }
        }
      } else {
        Text("Total: \(timePeriodActivity.doneCount)", bundle: .module)
          .font(.system(size: 14.0, weight: .bold))
          .foregroundStyle(Color.deepSpaceBlue)
      }
    }
    .formBackgroundModifier(color: .etherealLavender)
  }
}
