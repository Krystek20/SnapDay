import SwiftUI
import Resources

struct OnboardingFeatureHighlightView: View {

  @Binding var visibileHighlight: [OnboardingFeature.VisibileHighlight]
  @State private var shownHighlight: [OnboardingFeature.VisibileHighlight] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 40.0) {
      ForEach(visibileHighlight) { highlight in
        HStack(alignment: .top, spacing: 15.0) {
          Image(from: highlight.image)
            .resizable()
            .frame(width: 75.0, height: 75.0)
          VStack(alignment: .leading, spacing: 5.0) {
            Text(highlight.title)
              .font(.system(size: 20.0, weight: .semibold))
              .foregroundStyle(Color.standardText)
            Text(highlight.description)
              .font(.system(size: 14.0, weight: .regular))
              .foregroundStyle(Color.standardText)
              .lineSpacing(5.0)
              .multilineTextAlignment(.leading)
              .padding(.bottom, 5.0)
          }
        }
        .task {
          try? await Task.sleep(for: .seconds(0.5))
          withAnimation {
            shownHighlight.append(highlight)
          }
        }
        .opacity(shownHighlight.contains(highlight) ? 1.0 : .zero)
        .transition(.slide)
        .animation(.easeInOut, value: visibileHighlight)
      }
    }
  }
}

fileprivate extension OnboardingFeature.VisibileHighlight {
  var title: String {
    switch self {
    case .habitTracking:
      String(localized: "Simple Habit Tracking", bundle: .module)
    case .takeControl:
      String(localized: "Take Control of Your Day", bundle: .module)
    case .achieveGoals:
      String(localized: "Achieve Your Goals", bundle: .module)
    }
  }

  var description: String {
    switch self {
    case .habitTracking:
      String(localized: "Easily log your habits daily. Track your progress with clear visuals that keep you motivated and focused on your goals.", bundle: .module)
    case .takeControl:
      String(localized: "Tracking habits helps you stay focused, build consistency, and prioritize what matters most each day.", bundle: .module)
    case .achieveGoals:
      String(localized: "Set goals, track your progress, and build consistent habits to achieve what matters most.", bundle: .module)
    }
  }

  var image: Images {
    switch self {
    case .habitTracking:
      .onboardingFeatureHabitTracking
    case .takeControl:
      .onboardingFeatureTakeControl
    case .achieveGoals:
      .onboardingFeatureAchieveGoals
    }
  }
}
