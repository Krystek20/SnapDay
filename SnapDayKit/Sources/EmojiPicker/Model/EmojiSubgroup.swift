import Foundation

struct EmojiSubgroup: Decodable, Equatable, Identifiable {
  var id: String { name }
  let name: String
  let items: [Emoji]
}
