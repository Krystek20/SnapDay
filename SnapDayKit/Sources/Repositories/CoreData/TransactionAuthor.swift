import Foundation
import UIKit.UIDevice

struct TransactionAuthor {
  static func app(identifier: String = UIDevice.current.identifierForVendor?.uuidString ?? "", bundle: Bundle = .main) -> String {
    let widget = bundle.isWidgetExtension ? "Widget_" : ""
    return device + "_" + widget + identifier
  }

  private static var device: String {
    #if os(iOS)
      "iOS"
    #else
      "Unknown OS"
    #endif
  }
}
