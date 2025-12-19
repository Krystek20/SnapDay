import SwiftUI
import Resources
import Models

public struct CompletedActivitiesView: View {

  // MARK: - Properties

  private let completedActivities: CompletedActivities
  private let showBackground: Bool
  private let showProgressView: Bool

  // MARK: - Initialization

  public init(
    completedActivities: CompletedActivities,
    showBackground: Bool = true,
    showProgressView: Bool = true
  ) {
    self.completedActivities = completedActivities
    self.showBackground = showBackground
    self.showProgressView = showProgressView
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 10.0) {
      if showProgressView {
        CircularProgressView(
          progress: completedActivities.percent,
          lineWidth: 4.0
        )
        .frame(width: 20.0, height: 20.0)
      }
      Text("Completed activities", bundle: .module)
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.primaryText)
      Spacer()
      Text("\(completedActivities.doneCount) / \(completedActivities.totalCount)", bundle: .module)
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)
    }
    .padding(.all, 14.0)
    .background(backgroundColor)
  }

  @ViewBuilder
  private var backgroundColor: some View {
    if showBackground {
      Color.emphasisBackground
        .clipShape(RoundedCorner(radius: 12.0, corners: [.bottomLeft, .bottomRight]))
    } else {
      Color.clear.widgetAccentable()
    }
  }
}
