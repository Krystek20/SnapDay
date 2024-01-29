import Foundation
import SwiftUI

public enum ScenePhase {
  case active
  case inactive
  case background
}

extension ScenePhase {
  public init(_ scenePhase: SwiftUI.ScenePhase) {
    switch scenePhase {
    case .background:
      self = .background
    case .inactive:
      self = .inactive
    case .active:
      self = .active
    @unknown default:
      self = .active
    }
  }
}
