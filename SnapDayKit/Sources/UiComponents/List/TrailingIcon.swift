import Foundation
import SwiftUI

public enum TrailingIcon {
  case none
  case customView(any View)
}

extension TrailingIcon {
  public static var moreIcon: some View {
    Image(systemName: "ellipsis")
      .iconable(color: Color.sectionText)
  }
}
