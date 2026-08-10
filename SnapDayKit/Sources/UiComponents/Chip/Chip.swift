import SwiftUI
import Resources

public struct Chip: View {

  private let title: String
  private let systemImage: String?
  private let systemImageColor: Color

  public init(
    title: String,
    systemImage: String? = nil,
    systemImageColor: Color = .secondaryText
  ) {
    self.title = title
    self.systemImage = systemImage
    self.systemImageColor = systemImageColor
  }

  public var body: some View {
    HStack(spacing: 5.0) {
      if let systemImage {
        Image(systemName: systemImage)
          .font(.system(size: 12.0, weight: .semibold))
          .foregroundStyle(systemImageColor)
      }

      Text(title)
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)
        .lineLimit(1)
    }
    .padding(.horizontal, 10.0)
    .frame(height: 26.0)
    .background(
      Color.emphasisBackground
        .clipShape(RoundedRectangle(cornerRadius: 5.0))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 5.0)
        .stroke(Color.border, lineWidth: 1.0)
    )
  }
}
