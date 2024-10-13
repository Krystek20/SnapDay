import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models
import AppIntents
import Utilities

public struct WidgetStreakView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<WidgetStreakFeature>

  // MARK: - Initialization

  public init(store: StoreOf<WidgetStreakFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    content
      .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  @ViewBuilder
  private var content: some View {
    WithPerceptionTracking {
      content(image: store.image, contentType: store.contentType)
    }
  }

  private func content(
    image: Images,
    contentType: WidgetStreakFeature.State.ContentType
  ) -> some View {
    ZStack {
      ZStack(alignment: .top) {
        Image(from: image)
          .resizable()
          .scaledToFit()
          .padding(.horizontal, 25.0)
      }
      .maxFrame(alignment: .top)

      VStack(alignment: .center, spacing: .zero) {
        Spacer()
        switch contentType {
        case .start(let name):
          VStack(alignment: .leading, spacing: .zero) {
            Text(name)
              .lineLimit(1)
              .font(.system(size: 12.0, weight: .semibold))
              .foregroundStyle(Color.standardText)

            Text("Start growing your streak today!", bundle: .module)
              .font(.system(size: 12.0, weight: .regular))
              .foregroundStyle(Color.standardText)
          }
          .maxWidth()
        case .streak(let name, let current, let nextTitle, let next, let progress):
          HStack(alignment: .bottom, spacing: 5.0) {
            VStack(alignment: .leading, spacing: .zero) {
              Text(name)
                .lineLimit(1)
                .font(.system(size: 12.0, weight: .semibold))
                .foregroundStyle(Color.standardText)

              Text(nextTitle)
                .font(.system(size: 12.0, weight: .regular))
                .foregroundStyle(Color.standardText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: .zero) {
              Text(current)
                .font(.system(size: 34.0, weight: .bold))
                .foregroundStyle(Color.standardText)
                .offset(x: 2.5, y: 5.0)

              Text(next)
                .font(.system(size: 12.0, weight: .bold))
                .foregroundStyle(Color.standardText)
            }
          }
          .maxWidth()

          ProgressView(value: progress, total: 1.0)
            .tint(.actionBlue)
            .maxWidth()
            .padding(.top, 5.0)
        }
      }
      .padding(.bottom, 10.0)
      .padding(.horizontal, 10.0)
      .maxFrame(alignment: .bottom)
    }
  }
}
