import SwiftUI
import Resources
import Models
import UiComponents

private struct ActivityGroup: Identifiable {
  let id: String
  let activities: [Activity]

  init(_ activities: [Activity]) {
    self.id = activities.map(\.id.uuidString).joined()
    self.activities = activities
  }
}

private extension [Activity] {
  var activityGroups: [ActivityGroup] {
    stride(from: 0, to: count, by: 3).map {
      ActivityGroup(Array(self[$0..<Swift.min($0 + 3, count)]))
    }
  }
}

struct ActivitiesView: View {

  // MARK: - Properties

  private let activityGroups: [ActivityGroup]
  private let activityTapped: (Activity) -> Void
  private let activityEditTapped: (Activity) -> Void
  @State private var selectedIndex: String

  // MARK: - Initialization

  init(
    activities: [Activity],
    activityTapped: @escaping (Activity) -> Void,
    activityEditTapped: @escaping (Activity) -> Void
  ) {
    let activityGroups = activities.activityGroups
    self._selectedIndex = .init(initialValue: activityGroups.first?.id ?? .empty)
    self.activityGroups = activityGroups
    self.activityTapped = activityTapped
    self.activityEditTapped = activityEditTapped
  }

  // MARK: - Views

  var body: some View {
    VStack(spacing: 10.0) {
      ZStack {
        TabView(selection: $selectedIndex) {
          ForEach(activityGroups, content: activityView)
        }
        .frame(height: 75.0)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      }
      .formBackgroundModifier
      indicatorsViewIfNeeded
    }
  }

  private func activityView(_ activityGroup: ActivityGroup) -> some View {
    HStack {
      Spacer()
      ForEach(activityGroup.activities) { activity in
        VStack(spacing: 5.0) {
          ActivityImageView(data: activity.image, size: 50.0, cornerRadius: 25.0)
          Text(activity.name)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
            .foregroundStyle(Colors.slateHaze.swiftUIColor)
        }
        .padding(5.0)
        .background(Colors.pureWhite.swiftUIColor)
        .onTapGesture {
          activityTapped(activity)
        }
        .contextMenu {
          Button(
            action: {
              activityEditTapped(activity)
            },
            label: {
              Text("Edit", bundle: .module)
              Image(systemName: "pencil.circle")
            }
          )
        }
        Spacer()
      }
    }
    .tag(activityGroup.id)
  }

  @ViewBuilder
  private var indicatorsViewIfNeeded: some View {
    if activityGroups.count > 1 {
      LazyHStack(spacing: 5.0) {
        ForEach(activityGroups) { activityGroup in
          let scale = isSelected(activityGroup) ? 1.1 : 1.0
          Circle()
            .fill(isSelected(activityGroup) ? Colors.slateHaze.swiftUIColor : Colors.slateHaze.swiftUIColor.opacity(0.5))
            .scaleEffect(CGSize(width: scale, height: scale))
            .frame(width: 5.0, height: 5.0)
        }
      }
    }
  }

  private func isSelected(_ activityGroup: ActivityGroup) -> Bool {
    activityGroup.id == selectedIndex
  }
}
