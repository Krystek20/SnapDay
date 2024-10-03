import SwiftUI
import Resources

struct OnboardingCloudView: View {

  private let benefits = [
    (
      String(localized: "Local Storage", bundle: .module), 
      String(localized: "Your activity data stays on your device", bundle: .module)
    ),
    (
      String(localized: "End-to-End Encryption", bundle: .module), 
      String(localized: "If using iCloud, only you can access your information.", bundle: .module)),
    (
      String(localized: "Full Control", bundle: .module), 
      String(localized: "You decide where your data is stored.", bundle: .module)),
    (
      String(localized: "Privacy", bundle: .module), 
      String(localized: "No one else, not even us, can access your data.", bundle: .module)),
    (
      String(localized: "Sync Across Devices", bundle: .module), 
      String(localized: "Seamlessly manage your habits and goals with iCloud.", bundle: .module))
  ]

  var body: some View {
    VStack(spacing: 40.0) {
      VStack(alignment: .center, spacing: 5.0) {
        Image(from: .onboardingIcloud)
          .resizable()
          .frame(width: 100.0, height: 100.0)
        Text("Your Data, Your Control", bundle: .module)
          .font(.system(size: 20.0, weight: .semibold))
          .foregroundStyle(Color.standardText)
          .padding(.bottom, 5.0)
        Text("To help you track your habits, achieve goals, and manage your time, all your data is stored securely on your device or in iCloud.", bundle: .module)
          .fixedSize(horizontal: false, vertical: true)
          .font(.system(size: 14.0, weight: .regular))
          .foregroundStyle(Color.standardText)
          .lineSpacing(5.0)
          .multilineTextAlignment(.center)
      }

      VStack(alignment: .leading, spacing: 15.0) {
        ForEach(benefits, id: \.self.0) { benefit in
          HStack(alignment: .top, spacing: 10.0) {
            Image(systemName: "checkmark.circle.fill")
              .offset(y: 2.0)
            VStack(alignment: .leading, spacing: .zero) {
              Text(benefit.0)
                .font(.system(size: 16.0, weight: .medium))
                .foregroundStyle(Color.standardText)
              Text(benefit.1)
                .font(.system(size: 14.0, weight: .regular))
                .foregroundStyle(Color.sectionText)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      }
    }
  }
}
