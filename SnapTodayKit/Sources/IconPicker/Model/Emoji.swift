import Foundation

public struct Emoji: Decodable, Equatable, Identifiable {
  public var id: String { symbol }
  let symbol: String
  let description: String
}

extension Emoji {
  var emoji: String {
    let utf32 = symbol.components(separatedBy: " ")
      .compactMap { UInt32($0, radix: 16) }
      .compactMap(UnicodeScalar.init)
      .map(Character.init)
    return String(utf32)
  }
}
