import SwiftUI
import WidgetKit

public extension Image {

  private enum RenderingMode {
    case accented
    case desaturated

    @available(iOS 18.0, *)
    var widgetAccentedRenderingMode: WidgetAccentedRenderingMode {
      switch self {
      case .accented: .accented
      case .desaturated: .desaturated
      }
    }
  }

  func makeAccented(
    widgetRenderingMode: WidgetRenderingMode
  ) -> some View {
    handleWidgetRenderingMode(
      widgetRenderingMode: widgetRenderingMode,
      mode: .accented
    )
  }

  func makeDesaturated(
    widgetRenderingMode: WidgetRenderingMode
  ) -> some View {
    handleWidgetRenderingMode(
      widgetRenderingMode: widgetRenderingMode,
      mode: .desaturated
    )
  }

  @ViewBuilder
  private func handleWidgetRenderingMode(
    widgetRenderingMode: WidgetRenderingMode,
    mode: RenderingMode
  ) -> some View {
    switch widgetRenderingMode {
    case .accented, .vibrant:
      if #available(iOS 18.0, *) {
        widgetAccentedRenderingMode(mode.widgetAccentedRenderingMode)
      } else {
        background(.black)
          .compositingGroup()
          .luminanceToAlpha()
      }
    default:
      self
    }
  }
}
