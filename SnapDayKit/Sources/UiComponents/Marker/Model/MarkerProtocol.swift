import Models

public protocol MarkerProtocol: Equatable {
  var name: String { get }
  var rgbColor: RGBColor { get }
}
