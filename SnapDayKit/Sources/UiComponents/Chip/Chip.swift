import SwiftUI
import Models

public struct Chip: View {

  private let title: String

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    Text(title)
      .font(.system(size: 12.0, weight: .semibold))
      .foregroundStyle(Color.primaryText)
      .lineLimit(1)
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
