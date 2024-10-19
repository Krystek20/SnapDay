import Foundation
import SwiftUI

public enum TrailingIcon {
  case none
  case customView(any View)
}

extension TrailingIcon {
  public static var moreIcon: some View {
    Image(systemName: "ellipsis")
      .resizable()
      .scaledToFit()
      .frame(width: 15.0, height: 15.0)
      .foregroundStyle(Color.sectionText)
      .imageScale(.medium)
  }
}
