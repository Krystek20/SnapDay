import SwiftUI
import Models
import UiComponents

struct ActivityTaskView: View {

  // MARK: - Properties

  private let activityTask: ActivityTask
  private let editTapped: (ActivityTask) -> Void
  private let removeTapped: (ActivityTask) -> Void

  // MARK: - Initialization

  init(
    activityTask: ActivityTask,
    editTapped: @escaping (ActivityTask) -> Void,
    removeTapped: @escaping (ActivityTask) -> Void
  ) {
    self.activityTask = activityTask
    self.editTapped = editTapped
    self.removeTapped = removeTapped
  }

  // MARK: - Views

  var body: some View {
    Menu {
      Button(
        action: {
          editTapped(activityTask)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          removeTapped(activityTask)
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    } label: {
      activityTaskView(activityTask)
    }
  }

  private func activityTaskView(_ activityTask: ActivityTask) -> some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: activityTask.icon?.data,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: 2.0) {
        Text(activityTask.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
        subtitleView(for: activityTask)
      }
      Spacer()
      Image(systemName: "ellipsis")
        .foregroundStyle(Color.sectionText)
        .imageScale(.medium)
    }
  }

  @ViewBuilder
  private func subtitleView(for activityTask: ActivityTask) -> some View {
    HStack(spacing: 5.0) {
      if let textDuration = duration(for: activityTask) {
        Text(textDuration)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
      }
    }
  }

  // MARK: - Helpers

  private func duration(for activityTask: ActivityTask) -> String? {
    guard let defaultDuration = activityTask.defaultDuration, defaultDuration > .zero else { return nil }
    let minutes = defaultDuration % 60
    let hours = defaultDuration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }

}
