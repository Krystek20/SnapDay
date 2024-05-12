import Foundation
import UIKit.UIDevice

struct TransactionAuthor {
  static func app(identifier: String = UIDevice.current.identifierForVendor?.uuidString ?? "") -> String {
    device + "_" + identifier
  }

  private static var device: String {
    #if os(iOS)
      "iOS"
    #else
      "Unknown OS"
    #endif
  }
}
