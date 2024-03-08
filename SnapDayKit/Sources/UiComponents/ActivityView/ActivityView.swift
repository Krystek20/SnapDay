import SwiftUI
import Models
import Resources

public struct ActivityView: View {

  // MARK: - Properties

  private let activity: Activity

  // MARK: - Initialization

  public init(activity: Activity) {
    self.activity = activity
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 2.0) {
      ActivityImageView(
        data: activity.image,
        size: 20.0,
        cornerRadius: 5.0,
        tintColor: .deepSpaceBlue
      )
      Text(activity.name)
        .font(.system(size: 14.0, weight: .semibold))
        .foregroundStyle(Color.deepSpaceBlue)
    }
    .padding(
      EdgeInsets(
        top: 2.0,
        leading: 5.0,
        bottom: 2.0,
        trailing: 5.0
      )
    )
    .background(activityBackground)
  }

  // MARK: - Private

  private var activityBackground: some View {
    RoundedRectangle(cornerRadius: 3.0)
      .stroke(Color.deepSpaceBlue, lineWidth: 1.0)
      .padding(1.0)
  }
}
