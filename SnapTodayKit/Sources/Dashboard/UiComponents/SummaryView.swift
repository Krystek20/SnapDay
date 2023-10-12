import SwiftUI
import Resources
import Models

struct SummaryView: View {

  // MARK: - Properties

  let activities: [Activity]
  private let rows = [
    GridItem(.fixed(50.0)),
    GridItem(.fixed(50.0))
  ]

  // MARK: - Views

  var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      titleView
      scrollGridView
    }
    .padding(.all, 15.0)
    .maxWidth()
    .background(backgroundView)
  }

  private var titleView: some View {
    Text("Today", bundle: .module)
      .font(Fonts.Quicksand.bold.swiftUIFont(size: 22.0))
      .foregroundStyle(Colors.slateHaze.swiftUIColor)
  }

  private var scrollGridView: some View {
    ScrollView {
      LazyHGrid(rows: rows, spacing: 10.0) {
        ForEach(activities) { activity in
          imageView(for: activity)
            .frame(width: 50.0, height: 50.0)
            .background(activity.category.color.color.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
        }
      }
    }
  }

  @ViewBuilder 
  private func imageView(for activity: Activity) -> some View {
    if let emoji = activity.emoji {
      Text(emoji)
        .font(.system(size: 35.0))
        .opacity(activity.state == .toDo ? 0.15 : 1.0)
    }
  }

  @ViewBuilder 
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 20.0)
      .fill(Colors.skylineBlue.swiftUIColor)
  }
}
