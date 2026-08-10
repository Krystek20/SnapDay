import SwiftUI
import WidgetKit
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models
import AppIntents
import Utilities

public struct WeeklyProgressView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<WeeklyProgressFeature>
  @Environment(\.widgetRenderingMode) var widgetRenderingMode
  @State private var width: CGFloat?

  // MARK: - Initialization

  public init(store: StoreOf<WeeklyProgressFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    content
      .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  @ViewBuilder
  private var content: some View {
    VStack {
      progressView
      Spacer()
      summaryView
    }
    .padding(.all, 25.0)
    .maxFrame(alignment: .center)
  }

  private var progressView: some View {
    HStack(alignment: .center, spacing: 15.0) {
      ForEach(store.progressItems) { item in
        VStack(alignment: .center, spacing: 5.0) {

          switch widgetRenderingMode {
          case .accented, .vibrant:
            Text(item.state.icon)
              .font(.system(size: 24.0))
              .background(.black)
              .compositingGroup()
              .luminanceToAlpha()
          default:
            Text(item.state.icon)
              .font(.system(size: 24.0))
          }

          Text(item.label)
            .font(.system(size: 10.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)
        }
      }
    }
    .background(
      GeometryReader { proxy in
        Color.clear
          .onAppear {
            width = proxy.size.width
          }
      }
    )
  }

  private var summaryView: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 2.0) {
        if store.showTotalActivities {
          HStack(alignment: .bottom, spacing: 4.0) {
            Text("\(store.doneActivitiesCount)")
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.primaryText)
            Text("activities")
              .font(.system(size: 14.0, weight: .regular))
              .foregroundStyle(Color.primaryText)
          }
        }
        if store.showTotalSpentTime,
           let totalCompletedDuration = DateComponentsFormatter.duration(for: .minutes(store.days.totalCompletedDuration)) {
          HStack(alignment: .bottom, spacing: 4.0) {
            Text(totalCompletedDuration)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.primaryText)
            Text("spent")
              .font(.system(size: 14.0, weight: .regular))
              .foregroundStyle(Color.primaryText)
          }
        }
      }
      Spacer()
      Text("\(store.doneDaysCount) / \(store.days.count)")
        .font(.system(size: 34.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)
    }
    .frame(maxWidth: width ?? .infinity)
  }
}
