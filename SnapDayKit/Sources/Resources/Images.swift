import Foundation
import SwiftUI

public enum Images: String {
  case listEmpty = "list_empty"
  case listDone = "list_done"
  case activityListEmpty = "activity_list_empty"
}

public extension Image {
  init(from images: Images) {
    self.init(images.rawValue, bundle: .module)
  }
}
