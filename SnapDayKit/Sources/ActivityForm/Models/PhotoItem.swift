import _PhotosUI_SwiftUI

public struct PhotoItem: Equatable {

  // MARK: - Properties

  let photosPickerItem: PhotosPickerItem?

  // MARK: - Public

  func loadImageData(size: Double) async throws -> Data? {
    guard let data = try await photosPickerItem?.loadTransferable(type: Data.self),
          let image = UIImage(data: data) else { return nil }
    return scaleImageBy(image: image, size: size)?.pngData() ?? data
  }

  // MARK: - Private

  private func scaleImageBy(image: UIImage, size: Double) -> UIImage? {
    let imageSize = image.size

    guard min(imageSize.width, imageSize.height) > size else { return nil }
    let isPortraitOrSqure = imageSize.width <= imageSize.height

    let width = isPortraitOrSqure ? size : size * imageSize.width / imageSize.height
    let height = isPortraitOrSqure ? size * imageSize.height / imageSize.width : size
    let newSize = CGSize(width: width, height: height)

    UIGraphicsBeginImageContextWithOptions(newSize, false, .zero)
    defer { UIGraphicsEndImageContext() }
    image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
