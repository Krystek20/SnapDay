import SwiftUI
import UiComponents

struct PremiumLockedWidgetView: View {
  let title: LocalizedStringKey

  var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Image(systemName: "plus.circle.fill")
        .font(.system(size: 24.0, weight: .semibold))
        .foregroundStyle(Color.actionBlue)
      Spacer(minLength: .zero)
      VStack(alignment: .leading, spacing: 5.0) {
        Text(title)
          .font(.system(size: 16.0, weight: .bold))
          .foregroundStyle(Color.primaryText)
        Text("Available with SnapDay Plus")
          .font(.system(size: 12.0))
          .foregroundStyle(Color.secondaryText)
      }
    }
    .padding(15.0)
    .maxWidth(alignment: .leading)
  }
}
