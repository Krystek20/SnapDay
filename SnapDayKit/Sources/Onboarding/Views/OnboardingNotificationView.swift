import SwiftUI
import Resources

struct OnboardingNotificationView: View {
  var body: some View {
    VStack(alignment: .center, spacing: 5.0) {
      Image(from: .onboardingFeatureNotifications)
        .resizable()
        .frame(width: 100.0, height: 100.0)
      Text("Turn On Notifications to Reach Your Goals!", bundle: .module)
        .font(.system(size: 20.0, weight: .semibold))
        .lineSpacing(5.0)
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.standardText)
        .padding(.bottom, 5.0)
      Text("Stay on top of your progress and reach your goals faster—enable notifications to get timely reminders and track your activities effortlessly!", bundle: .module)
        .fixedSize(horizontal: false, vertical: true)
        .font(.system(size: 14.0, weight: .regular))
        .foregroundStyle(Color.standardText)
        .lineSpacing(5.0)
        .multilineTextAlignment(.center)
    }
  }
}
