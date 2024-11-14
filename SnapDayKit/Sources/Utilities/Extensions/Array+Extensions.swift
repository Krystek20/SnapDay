import Foundation

extension Array {
  public func chunked(into size: Int) -> [[Element]] {
    stride(from: .zero, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
