import Models

extension RGBColorEntity {
  func setup(by color: RGBColor) {
    identifier = color.id
    red = color.red
    green = color.green
    blue = color.blue
    alpha = color.alpha
  }
}
