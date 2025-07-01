import SwiftUI
import Resources
import Models
import Utilities

public struct ActivitySummaryGrid: View {

  // MARK: - Properties

  private let timePeriodActivities: [TimePeriodActivity]
  private let itemTapped: (TimePeriodActivity) -> Void
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(
    timePeriodActivities: [TimePeriodActivity],
    itemTapped: @escaping (TimePeriodActivity) -> Void
  ) {
    self.timePeriodActivities = timePeriodActivities
    self.itemTapped = itemTapped
  }

  // MARK: - Views

  public var body: some View {
      activityDetailsSectionView
  }

  private var activityDetailsSectionView: some View {
    LazyVGrid(columns: columns, spacing: 15.0) {
      ForEach(timePeriodActivities) { timePeriodActivity in

        VStack(alignment: .leading, spacing: 2.5) {
          switch timePeriodActivity.type {
          case .icon(let iconId):
            ImageView(
              type: .iconId(iconId),
              size: 40.0,
              cornerRadius: 20.0
            )
            Text(timePeriodActivity.name)
              .font(.system(size: 12.0, weight: .semibold))
              .multilineTextAlignment(.leading)
              .lineLimit(2)
              .foregroundStyle(Color.sectionText)
          case .color(let rgbColor):
            Text(timePeriodActivity.name)
              .font(.system(size: 12.0, weight: .semibold))
              .multilineTextAlignment(.leading)
              .lineLimit(2)
              .foregroundStyle(
                rgbColor.isLight() ? Color.sectionText : Color.pureWhite
              )
              .padding(
                EdgeInsets(
                  top: 2.0,
                  leading: 5.0,
                  bottom: 2.0,
                  trailing: 5.0
                )
              )
              .background(
                rgbColor.color
                  .clipShape(RoundedRectangle(cornerRadius: 3.0))
              )
          }

          if timePeriodActivity.duration > .zero {
            Text(TimeProvider.duration(from: timePeriodActivity.duration, bundle: .module) ?? "")
              .font(.system(size: 12.0, weight: .regular))
              .foregroundStyle(Color.sectionText)
          }

          Spacer(minLength: 5.0)

          if timePeriodActivity.showProgress {
            ProgressView(value: timePeriodActivity.completedValue) {
              HStack(alignment: .bottom) {
                Text("\(timePeriodActivity.percent)%", bundle: .module)
                  .font(.system(size: 12.0, weight: .regular))
                  .foregroundStyle(Color.standardText)
                Spacer()
                Text("\(timePeriodActivity.doneCount) / \(timePeriodActivity.totalCount)", bundle: .module)
                  .font(.system(size: 12.0, weight: .regular))
                  .foregroundStyle(Color.sectionText)
              }
            }
            .tint(.actionBlue)
          } else {
            Text("Total: \(timePeriodActivity.doneCount)", bundle: .module)
              .font(.system(size: 12.0, weight: .regular))
              .foregroundStyle(Color.sectionText)
          }
        }
        .maxFrame()
        .formBackgroundModifier()
        .onTapGesture {
          itemTapped(timePeriodActivity)
        }
      }
    }
  }
}
