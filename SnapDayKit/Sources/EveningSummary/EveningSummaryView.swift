import SwiftUI
import ComposableArchitecture
import UiComponents
import Utilities

public struct EveningSummaryView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<EveningSummaryFeature>
  public var sizeChanged: ((CGSize) -> Void)?

  // MARK: - Initialization

  public init(store: StoreOf<EveningSummaryFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: .zero) {
        VStack(alignment: .leading, spacing: 10.0) {
          VStack(alignment: .leading, spacing: 5.0) {
            Text("TODAY'S TRIUMPHS", bundle: .module)
              .font(.system(size: 14.0, weight: .regular))
              .foregroundStyle(Color.sectionText)
            description
              .fixedSize(horizontal: false, vertical: true)
          }

          ForEach(store.eveningTagSummaries) { eveningTagSummary in
            VStack(alignment: .leading, spacing: 5.0) {
              HStack {
                MarkerView(marker: eveningTagSummary.tag)
                Spacer()
                if eveningTagSummary.totalDuration > .zero {
                  DurationLabel(duration: eveningTagSummary.totalDuration)
                }
              }
              ForEach(eveningTagSummary.dayActivities) { dayActivity in
                ActivitySummaryRow(
                  activityType: .dayActivity(dayActivity),
                  durationType: .fromActivity
                )
              }
            }
          }
          .formBackgroundModifier()
        }
        .padding(.top, 10.0)
        .padding(.horizontal, 10.0)

        CompletedActivitiesView(completedActivities: store.completedActivities)
          .padding(.top, 10.0)
      }
      .background(
        GeometryReader { geometry in
          contentViewChanged(size: geometry.size)
        }
      )
      .onAppear {
        store.send(.view(.appeared))
      }
    }
  }

  private var description: some View {
    WithPerceptionTracking {
      Group {
        if store.doneActivitiesCount > 0 {
          allDoneText + totalTimeText + Text(" ") + greatWorkText
        } else {
          noActivitiesText
        }
      }
      .font(.system(size: 14.0, weight: .regular))
    }
  }

  private var totalTimeText: Text {
    if let duration = TimeProvider.duration(from: store.doneActivitiesDuration, bundle: .module) {
      activitiesWithDuration(durationText: duration)
    } else {
      activitiesWithoutDuration
    }
  }

  private var allDoneText: Text {
    if store.showDoneView {
      Text("Who's awesome? You are! 🌟 All your activities for today are checked off. Time to kick back and enjoy your evening. You've earned it! ", bundle: .module)
    } else {
      Text("")
    }
  }

  private func activitiesWithDuration(durationText: String) -> Text {
    Text("You've successfully completed **\(store.doneActivitiesCount) activities**, totaling **\(durationText)** of productive time.")
  }

  private var activitiesWithoutDuration: Text {
    Text("You've successfully completed **\(store.doneActivitiesCount) activities**.")
  }

  private var greatWorkText: Text {
    Text("Great work staying on track and pushing your limits!", bundle: .module)
  }

  private var noActivitiesText: Text {
    Text("It looks like you didn't complete any activities today. Don't be discouraged! Tomorrow is a new day to set your goals and achieve them. Remember, every small step counts towards your progress!", bundle: .module)
  }

  private func contentViewChanged(size: CGSize) -> some View {
    sizeChanged?(size)
    return Color.background
      .ignoresSafeArea()
  }
}
