import SwiftUI
import Resources
import Utilities
import Models

public struct ActivitiesByTagView: View {

  // MARK: - Properties

  private let tagActivitySections: [TagActivitySection]
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]
  @Binding private var selectedTag: Tag?

  // MARK: - Initialization

  public init(selectedTag: Binding<Tag?>, tagActivitySections: [TagActivitySection]) {
    self.tagActivitySections = tagActivitySections
    self._selectedTag = selectedTag
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      ScrollView(.horizontal) {
        HStack(spacing: 10.0) {
          ForEach(tagActivitySections.map(\.tag), content: tagView)
        }
      }
      if let tagActivitySection = tagActivitySections.first(where: { $0.tag == selectedTag }) {
        activityDetailsSectionView(tagActivitySection)
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

  private func activityDetailsSectionView(_ section: TagActivitySection) -> some View {
    LazyVGrid(columns: columns, spacing: 15.0) {
      ForEach(section.timePeriodActivities, content: activityDetailsView)
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
          .foregroundStyle(Color.sectionText)
        Spacer()
      }

      if timePeriodActivity.duration > .zero {
        HStack {
          Image(systemName: "clock")
            .foregroundStyle(Color.sectionText)
            .imageScale(.small)
          Text(TimeProvider.duration(from: timePeriodActivity.duration, bundle: .module) ?? "")
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.sectionText)
        }
      }

      if timePeriodActivity.activity.isRepeatable {
        ProgressView(value: timePeriodActivity.completedValue) {
          HStack(alignment: .bottom) {
            Text("\(timePeriodActivity.percent)%", bundle: .module)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.standardText)
            Spacer()
            Text("\(timePeriodActivity.doneCount) / \(timePeriodActivity.totalCount)", bundle: .module)
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.sectionText)
          }
        }
      } else {
        Text("Total: \(timePeriodActivity.doneCount)", bundle: .module)
          .font(.system(size: 14.0, weight: .bold))
          .foregroundStyle(Color.standardText)
      }
    }
    .formBackgroundModifier(color: .selection)
  }
}
