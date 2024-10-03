import SwiftUI
import Resources

struct OnboardingWelcomeView: View {
  var body: some View {
    VStack(spacing: .zero) {
      Image(from: .onboardingWelcome)
        .resizable()
        .frame(width: 250.0, height: 250.0)
      Text("Welcome to SnapDay!", bundle: .module)
        .titleTextStyle
        .multilineTextAlignment(.center)
        .padding(.bottom, 15.0)
      Text("Build Better Habits, One Step at a Time", bundle: .module)
        .font(.system(size: 16.0, weight: .semibold))
        .foregroundStyle(Color.standardText)
        .lineSpacing(5.0)
        .multilineTextAlignment(.center)
        .padding(.bottom, 10.0)
      Text("We help you track daily activities, set goals, and stay motivated. Start your journey to a better you!", bundle: .module)
        .font(.system(size: 14.0, weight: .regular))
        .foregroundStyle(Color.standardText)
        .lineSpacing(5.0)
        .multilineTextAlignment(.center)
    }
  }
}
