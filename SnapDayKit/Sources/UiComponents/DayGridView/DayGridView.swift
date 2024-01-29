import SwiftUI
import Resources
import Models

public struct DayGridView: View {

  // MARK: - Properties

  private let isPastDay: Bool
  private let activities: [DayActivity]
  private let activityTapped: (DayActivity) -> Void
  private let editTapped: (DayActivity) -> Void
  private let removeTapped: (DayActivity) -> Void

  private var columns: [GridItem] {
    Array(repeating: GridItem(.fixed(40.0)), count: 6)
  }

  // MARK: - Initialization

  public init(
    isPastDay: Bool,
    activities: [DayActivity],
    activityTapped: @escaping (DayActivity) -> Void,
    editTapped: @escaping (DayActivity) -> Void,
    removeTapped: @escaping (DayActivity) -> Void
  ) {
    self.isPastDay = isPastDay
    self.activities = activities
    self.activityTapped = activityTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
  }

  // MARK: - Views

  public var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 10.0) {
      ForEach(activities, content: activityIcon)
    }
    .formBackgroundModifier
  }

  private func activityIcon(dayActivity: DayActivity) -> some View {
    ActivityImageView(
      data: dayActivity.activity.image,
      size: 40.0,
      cornerRadius: 20.0
    )
    .opacity(dayActivity.isDone ? 1.0 : 0.3)
    .contextMenu {
      Button(
        action: {
          editTapped(dayActivity)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )

      Button(
        action: {
          removeTapped(dayActivity)
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    }
    .onTapGesture {
      activityTapped(dayActivity)
    }
  }

  // MARK: - Helpers

  private func duration(for dayActivity: DayActivity) -> String? {
    guard dayActivity.duration > .zero else { return nil }
    let minutes = dayActivity.duration % 60
    let hours = dayActivity.duration / 60
    return String(localized: "\(hours)h \(minutes)min", bundle: .module)
  }
}
