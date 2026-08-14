import Resources
import SwiftUI
import UiComponents

struct DashboardNotificationPromptView: View {

  let dismissAction: () -> Void
  let turnOnAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      HStack(alignment: .top, spacing: 10.0) {
        Image(systemName: "bell.badge.fill")
          .font(.title3)
          .foregroundStyle(Color.actionBlue)
          .frame(width: 30.0, height: 30.0)

        VStack(alignment: .leading, spacing: 5.0) {
          Text("Stay on track", bundle: .module)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.primaryText)

          Text(
            "Get reminders for today's activities and plan sessions.",
            bundle: .module
          )
          .font(.footnote)
          .foregroundStyle(Color.secondaryText)
        }
        .padding(.trailing, 30.0)
      }

      Button(
        String(localized: "Turn on", bundle: .module),
        action: turnOnAction
      )
      .buttonStyle(PrimaryButtonStyle(height: .small))
    }
    .padding(15.0)
    .overlay(alignment: .topTrailing) {
      Button(action: dismissAction) {
        Image(systemName: "xmark")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(Color.secondaryText)
          .frame(width: 30.0, height: 30.0)
      }
      .accessibilityLabel(Text("Dismiss", bundle: .module))
      .padding([.top, .trailing], 5.0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.formBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8.0))
  }
}
