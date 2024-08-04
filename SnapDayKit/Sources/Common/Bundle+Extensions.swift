import Foundation

extension Bundle {
  public var isMainApp: Bool {
    !bundlePath.hasSuffix(".appex")
  }

  public var isWidgetExtension: Bool {
    guard let extensionInfo = infoDictionary?["NSExtension"] as? [String: String],
          let extensionPointIdentifier = extensionInfo["NSExtensionPointIdentifier"] else { return false }
    return extensionPointIdentifier == "com.apple.widgetkit-extension"
  }
}
