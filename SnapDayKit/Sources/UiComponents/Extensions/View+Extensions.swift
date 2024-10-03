import SwiftUI

extension View {
  public func maxFrame(alignment: Alignment = .topLeading) -> some View {
    frame(
      minWidth: .zero,
      maxWidth: .infinity,
      minHeight: .zero,
      maxHeight: .infinity,
      alignment: alignment
    )
  }

  public func maxWidth(alignment: Alignment = .topLeading) -> some View {
    frame(
      minWidth: .zero,
      maxWidth: .infinity,
      alignment: alignment
    )
  }
}

extension View {
  public func scrollOnAppear<ID>(_ id: ID, anchor: UnitPoint? = nil, reader: ScrollViewProxy) -> some View where ID: Hashable {
    onAppear {
      withAnimation {
        reader.scrollTo(id, anchor: anchor)
      }
    }
  }
}
