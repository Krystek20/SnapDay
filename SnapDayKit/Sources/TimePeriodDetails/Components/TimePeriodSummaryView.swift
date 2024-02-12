import SwiftUI
import Resources
import Utilities
import UiComponents
import Models

struct TimePeriodSummaryView: View {

  // MARK: - Properties

  private let timePeriodActivitySections: [TimePeriodActivitySection]
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]
  @Binding private var selectedTag: Tag?

  // MARK: - Initialization

  init(selectedTag: Binding<Tag?>, timePeriodActivitySections: [TimePeriodActivitySection]) {
    self.timePeriodActivitySections = timePeriodActivitySections
    self._selectedTag = selectedTag
  }

  // MARK: - Views

  var body: some View {
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
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
          .foregroundStyle(Colors.slateHaze.swiftUIColor)
        Spacer()
      }

      if timePeriodActivity.duration > .zero {
        HStack {
          Image(systemName: "clock")
            .foregroundStyle(Colors.slateHaze.swiftUIColor)
            .imageScale(.small)
          Text(TimeProvider.duration(from: timePeriodActivity.duration, bundle: .module) ?? "")
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.slateHaze.swiftUIColor)
        }
      }

      if timePeriodActivity.activity.isRepeatable {
        ProgressView(value: timePeriodActivity.completedValue) {
          HStack(alignment: .bottom) {
            Text("\(timePeriodActivity.percent)%", bundle: .module)
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
            Spacer()
            Text("\(timePeriodActivity.doneCount) / \(timePeriodActivity.totalCount)", bundle: .module)
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.slateHaze.swiftUIColor)
          }
        }
      } else {
        Text("Total: \(timePeriodActivity.doneCount)", bundle: .module)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
    }
    .formBackgroundModifier
  }
}
