import SwiftUI
import Models
import UiComponents

struct DayActivityTaskRowView: View {

  // MARK: - Properties

  private let dayActivityTask: DayActivityForm
  private let selectTapped: (DayActivityForm) -> Void
  private let editTapped: (DayActivityForm) -> Void
  private let removeTapped: (DayActivityForm) -> Void

  // MARK: - Initialization

  init(
    dayActivityTask: DayActivityForm,
    selectTapped: @escaping (DayActivityForm) -> Void,
    editTapped: @escaping (DayActivityForm) -> Void,
    removeTapped: @escaping (DayActivityForm) -> Void
  ) {
    self.dayActivityTask = dayActivityTask
    self.selectTapped = selectTapped
    self.editTapped = editTapped
    self.removeTapped = removeTapped
  }

  // MARK: - Views

  var body: some View {
    Menu {
      Button(
        action: {
          selectTapped(dayActivityTask)
        },
        label: {
          if dayActivityTask.completed {
            Text("Deselect", bundle: .module)
            Image(systemName: "x.circle")
          } else {
            Text("Select", bundle: .module)
            Image(systemName: "checkmark.circle")
          }
        }
      )
      Button(
        action: {
          editTapped(dayActivityTask)
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
      Button(
        action: {
          removeTapped(dayActivityTask)
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    } label: {
      dayActivityTaskView(dayActivityTask)
    }
  }

  private func dayActivityTaskView(_ dayActivityTask: DayActivityForm) -> some View {
    HStack(spacing: 5.0) {
      ActivityImageView(
        data: dayActivityTask.icon?.data,
        size: 30.0,
        cornerRadius: 15.0
      )
      VStack(alignment: .leading, spacing: .zero) {
        Text(dayActivityTask.name)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.completed, color: .sectionText)
        subtitleView(for: dayActivityTask)
      }
      Spacer()
      Image(systemName: "ellipsis")
        .foregroundStyle(Color.sectionText)
        .imageScale(.medium)
    }
  }

  @ViewBuilder
  private func subtitleView(for dayActivityTask: DayActivityForm) -> some View {
    HStack(spacing: 5.0) {
      if !dayActivityTask.overview.isEmpty {
        Text(dayActivityTask.overview)
          .font(.system(size: 12.0, weight: .regular))
          .lineLimit(1)
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.completed, color: .sectionText)
      }

      if let textDuration = duration(for: dayActivityTask.duration) {
        if !dayActivityTask.overview.isEmpty {
          Text("-")
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.sectionText)
        }

        Text(textDuration)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
          .strikethrough(dayActivityTask.completed, color: .sectionText)
      }
    }
  }

  // MARK: - Helpers

  private func duration(for duration: Int) -> String? {
    guard duration > .zero else { return nil }
    let minutes = duration % 60
    let hours = duration / 60
    return hours > .zero
    ? String(localized: "\(hours)h \(minutes)min", bundle: .module)
    : String(localized: "\(minutes)min", bundle: .module)
  }
}
