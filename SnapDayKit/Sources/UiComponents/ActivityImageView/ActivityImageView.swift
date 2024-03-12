import SwiftUI
import Resources

public struct ActivityImageView: View {

  // MARK: - Properties

  private let data: Data?
  private let size: Double
  private let cornerRadius: Double
  private let tintColor: Color

  // MARK: - Initialization

  public init(
    data: Data?,
    size: Double = 70.0,
    cornerRadius: Double = 15.0,
    tintColor: Color = .sectionText
  ) {
    self.data = data
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
    image
      .resizable()
      .scaledToFill()
      .fontWeight(.ultraLight)
      .frame(width: size, height: size)
      .foregroundStyle(tintColor)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }

  private var image: Image {
    if let imageData = data, let image = UIImage(data: imageData) {
      Image(uiImage: image)
    } else {
      Image(systemName: "photo.circle")
    }
  }
}
