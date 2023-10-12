import SwiftUI
import Resources
import Models

struct ActivityView: View {

  // MARK: - Properties

  let activity: Activity

  // MARK: - Views

  var body: some View {
    HStack(alignment: .center, spacing: 15.0) {
      imageView
        .frame(width: 70.0, height: 70.0)
        .background(imageViewBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
      VStack(alignment: .leading, spacing: .zero) {
        Text(activity.name)
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
        Text("Last activity 2 days ago")
          .font(Fonts.Quicksand.regular.swiftUIFont(size: 14.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
    }
    .maxWidth()
    .padding(.all, 10.0)
    .background(
      activity.category.color.color.opacity(0.1)
        .clipShape(RoundedRectangle(cornerRadius: 20.0))
    )
    .overlay {
      RoundedRectangle(cornerRadius: 20.0)
        .stroke(Colors.slateHaze.swiftUIColor.opacity(0.2), lineWidth: 1.0)
    }
  }

  @ViewBuilder 
  private var imageView: some View {
    if let emoji = activity.emoji {
      Text(emoji)
        .font(.system(size: 40.0))
    }
  }

  private var imageViewBackground: some View {
    LinearGradient(
      gradient: Gradient(
        colors: [
          Colors.lilacMist.swiftUIColor,
          Colors.skyWhisper.swiftUIColor
        ]
      ), 
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
