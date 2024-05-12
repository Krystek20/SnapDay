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
      allDoneText +
      Text("You've successfully completed")
        .font(.system(size: 14.0, weight: .regular)) +
      Text(" \(store.doneActivitiesCount) activities ")
        .font(.system(size: 14.0, weight: .bold)) +
      Text("today, totaling ")
        .font(.system(size: 14.0, weight: .regular)) +
      Text("\(TimeProvider.duration(from: store.doneActivitiesDuration, bundle: .module) ?? "")")
        .font(.system(size: 14.0, weight: .bold)) +
      Text(" of productive time. Great work staying on track and pushing your limits!")
        .font(.system(size: 14.0, weight: .regular))
    }
  }

  private var allDoneText: Text {
    if store.showDoneView {
      Text("Who's awesome? You are! 🌟 All your activities for today are checked off. Time to kick back and enjoy your evening. You've earned it!", bundle: .module)
        .font(.system(size: 14.0, weight: .regular))
    } else {
      Text("")
    }
  }

  private func contentViewChanged(size: CGSize) -> some View {
    sizeChanged?(size)
    return Color.background
      .ignoresSafeArea()
  }
}
