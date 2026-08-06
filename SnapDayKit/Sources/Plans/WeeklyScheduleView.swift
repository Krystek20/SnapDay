import ComposableArchitecture
import Models
import Resources
import SwiftUI
import UiComponents

@MainActor
struct WeeklyScheduleView: View {

  let store: StoreOf<NewPlanFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        planSection
        scheduleSection
      }
      .padding(15.0)
    }
    .scrollIndicators(.hidden)
  }

  private var planSection: some View {
    NewPlanSection(title: String(localized: "PLAN", bundle: .module)) {
      HStack(alignment: .top, spacing: 10.0) {
        VStack(alignment: .leading, spacing: 5.0) {
          Text(store.name)
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)

          Text(dateRangeTitle)
            .font(.system(size: 13.0, weight: .regular))
            .foregroundStyle(Color.secondaryText)
        }

        Spacer(minLength: 10.0)

        Text(String(localized: store.selectedDuration.title, bundle: .module))
          .font(.system(size: 13.0, weight: .regular))
          .foregroundStyle(Color.sectionText)
      }
      .padding(15.0)
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var scheduleSection: some View {
    NewPlanSection(title: String(localized: "WEEKLY SCHEDULE", bundle: .module)) {
      VStack(spacing: .zero) {
        ForEach(Array(store.schedule.enumerated()), id: \.element.id) { index, day in
          ScheduleDayRow(store: store, day: day)

          if index < store.schedule.count - 1 {
            Divider()
              .padding(.horizontal, 15.0)
          }
        }
      }
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )

      if !store.canReview {
        Text("Add at least one activity to one available day.", bundle: .module)
          .font(.system(size: 13.0, weight: .regular))
          .foregroundStyle(
            store.isScheduleValidationErrorPresented
              ? Color.alertText
              : Color.sectionText
          )
          .padding(.horizontal, 10.0)
          .padding(.top, 5.0)
      }
    }
  }

  private var dateRangeTitle: String {
    let start = store.startDate.formatted(.dateTime.day().month(.abbreviated))
    let end = store.endDate.formatted(.dateTime.day().month(.abbreviated))
    return "\(start) - \(end) · \(String(localized: "Repeats weekly", bundle: .module))"
  }
}

@MainActor
private struct ScheduleDayRow: View {

  let store: StoreOf<NewPlanFeature>
  let day: ScheduledPlanDay

  var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      HStack(alignment: .center, spacing: 10.0) {
        VStack(alignment: .leading, spacing: 5.0) {
          Text(day.weekday.title)
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)

          Text(activitySummary)
            .font(.system(size: 13.0, weight: .regular))
            .foregroundStyle(Color.secondaryText)
        }

        Spacer(minLength: 10.0)

        Menu {
          Button {
            store.send(.view(.addActivityTapped(day.weekday)))
          } label: {
            Label(String(localized: "Add activity", bundle: .module), systemImage: "plus")
          }

          Button {
            store.send(.view(.applyToDaysTapped(day.weekday)))
          } label: {
            Label(String(localized: "Apply to days", bundle: .module), systemImage: "calendar.badge.plus")
          }
          .disabled(day.activities.isEmpty)
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.actionBlue)
            .frame(width: 40.0, height: 40.0)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("Day actions", bundle: .module))
      }

      if !day.activities.isEmpty {
        ScrollView(.horizontal) {
          HStack(spacing: 5.0) {
            ForEach(day.activities) { activity in
              Chip(title: activity.name)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
    .padding(15.0)
  }

  private var activitySummary: String {
    switch day.activities.count {
    case 0:
      String(localized: "No activities planned", bundle: .module)
    case 1:
      String(localized: "1 activity", bundle: .module)
    default:
      String(localized: "\(day.activities.count) activities", bundle: .module)
    }
  }
}
