import SwiftUI
import Resources
import Utilities
import Dependencies

public enum ActivityImageType: Equatable {
  case iconId(UUID?)
  case data(Data)
  case placeholder
  case empty
}

public struct ActivityImageView: View {

  // MARK: - Properties

  private let type: ActivityImageType
  private let size: Double
  private let cornerRadius: Double
  private let tintColor: Color

  // MARK: - Initialization

  public init(
    type: ActivityImageType,
    size: Double = 70.0,
    cornerRadius: Double = 15.0,
    tintColor: Color = .sectionText
  ) {
    self.type = type
    self.size = size
    self.cornerRadius = cornerRadius
    self.tintColor = tintColor
  }

  // MARK: - Views

  public var body: some View {
    imageView
  }

  @ViewBuilder
  private var imageView: some View {
    iconView
      .frame(width: size, height: size)
      .foregroundStyle(tintColor)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }

  private var iconView: some View {
    switch type {
    case .iconId(let iconId):
      if let iconId {
        AnyView(
          LoadableImage(
            iconId: iconId,
            placeholder: Image(systemName: "photo.circle")
          )
            .id(iconId)
        )
      } else {
        AnyView(placeholder)
      }
    case .data(let data):
      if let uiImage = UIImage(data: data) {
        AnyView(
          Image(uiImage: uiImage)
            .applyIconProperties()
        )
      } else {
        AnyView(placeholder)
      }
    case .placeholder:
      AnyView(placeholder)
    case .empty:
      AnyView(EmptyView())
    }
  }

  private var placeholder: some View {
    Image(systemName: "photo.circle")
      .applyIconProperties()
  }
}

private struct LoadableImage: View {

  private let iconId: UUID
  @State private var image: Image?
  private let placeholder: Image
  @Dependency(\.iconProvider) private var iconProvider

  init(
    iconId: UUID,
    placeholder: Image
  ) {
    self.iconId = iconId
    self.placeholder = placeholder
  }

  var body: some View {
    content
      .task {
        await loadImage()
      }
      .onReceive(iconProvider.iconChangedPublisher) { iconId in
        guard iconId == self.iconId else { return }
        Task { @MainActor in
          await loadImage()
        }
      }
  }

  private var content: some View {
    if let image {
      AnyView(
        image.applyIconProperties()
      )
    } else {
      AnyView(
        Color.clear
      )
    }
  }

  private func loadImage() async {
    image = nil
    guard let icon = await iconProvider.getIcon(id: iconId),
          let iconData = icon.data,
          let uiImage = UIImage(data: iconData) else {
      image = placeholder
      return
    }
    image = Image(uiImage: uiImage)
  }
}

private extension Image {
  func applyIconProperties() -> some View {
    resizable()
      .scaledToFill()
      .fontWeight(.ultraLight)
  }
}
