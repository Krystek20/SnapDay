import ComposableArchitecture
import Resources
import SwiftUI
import Utilities

@MainActor
struct NewPlanReviewView: View {

  let store: StoreOf<NewPlanFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        summarySection
        scheduleSection
      }
      .padding(15.0)
    }
    .scrollIndicators(.hidden)
  }

  private var summarySection: some View {
    NewPlanSection(title: String(localized: "Plan", bundle: .module)) {
      VStack(alignment: .leading, spacing: 10.0) {
        Text(store.name)
          .font(.system(size: 19.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)

        Text(dateRangeTitle)
          .font(.system(size: 13.0, weight: .regular))
          .foregroundStyle(Color.secondaryText)

        Divider()

        HStack(spacing: 10.0) {
          Text("Planned activities", bundle: .module)
            .font(.system(size: 15.0, weight: .regular))
            .foregroundStyle(Color.primaryText)

          Spacer(minLength: 10.0)

          Text("\(plannedActivityCount)")
            .font(.system(size: 15.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)
        }
      }
      .padding(15.0)
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var scheduleSection: some View {
    NewPlanSection(title: String(localized: "Weekly schedule", bundle: .module)) {
      VStack(spacing: .zero) {
        ForEach(Array(store.schedule.enumerated()), id: \.element.id) { index, day in
          HStack(alignment: .top, spacing: 10.0) {
            Text(day.weekday.title)
              .font(.system(size: 15.0, weight: .semibold))
              .foregroundStyle(Color.primaryText)
              .frame(width: 95.0, alignment: .leading)

            if day.activities.isEmpty {
              Text("No activities", bundle: .module)
                .font(.system(size: 13.0, weight: .regular))
                .foregroundStyle(Color.secondaryText)
            } else {
              VStack(alignment: .leading, spacing: 5.0) {
                ForEach(day.activities) { activity in
                  Text(activity.name)
                    .font(.system(size: 13.0, weight: .regular))
                    .foregroundStyle(Color.primaryText)
                }
              }
            }

            Spacer(minLength: .zero)
          }
          .padding(15.0)

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
    }
  }

  private var dateRangeTitle: String {
    let calendar = Calendar.autoupdatingCurrent.utcCalendar
    let start = store.startDate.formatted(template: "yMMMd", calendar: calendar)
    let end = store.endDate.formatted(template: "yMMMd", calendar: calendar)
    return "\(start) – \(end)"
  }

  private var plannedActivityCount: Int {
    NewPlanDraft(
      name: store.name,
      duration: store.selectedDuration,
      startDate: store.startDate,
      endDate: store.endDate,
      schedule: store.schedule
    )
    .plannedActivityCount()
  }
}
