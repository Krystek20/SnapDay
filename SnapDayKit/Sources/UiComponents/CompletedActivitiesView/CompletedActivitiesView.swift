import SwiftUI
import Models

public struct CompletedActivitiesView: View {

  // MARK: - Properties

  private let completedActivities: CompletedActivities

  // MARK: - Initialization

  public init(completedActivities: CompletedActivities) {
    self.completedActivities = completedActivities
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 10.0) {
      CircularProgressView(
        progress: completedActivities.percent,
        lineWidth: 4.0
      )
      .frame(width: 20.0, height: 20.0)
      Text("Completed activities", bundle: .module)
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.standardText)
      Spacer()
      Text("\(completedActivities.doneCount) / \(completedActivities.totalCount)", bundle: .module)
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.standardText)
    }
    .padding(.all, 14.0)
    .background(Color.selection)
  }
}
