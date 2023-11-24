import Foundation
import Models

#warning("Helper to remove")
extension Date {
  static func date(from string: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
    return dateFormatter.date(from: string) ?? Date()
  }
}

extension Activity {
  static let mock = Activity(
    id: UUID(1),
    name: "Siłownia",
    image: "🏋️‍♀️".emojiToImage(size: 70.0).pngData(),
    tags: []
  )
}

extension Tag {
  static let mock = Tag(
    name: "Sport",
    color: .random
  )
}

extension [Activity] {
  static let mock = [
    Activity(
      id: UUID(1),
      name: "Siłownia",
      image: "🏋️‍♀️".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Sport",
          color: .random
        )
      ]
    ),
    Activity(
      id: UUID(2),
      name: "Joga",
      image: "🧘".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Sport",
          color: .random
        )
      ]
    ),
    Activity(
      id: UUID(3),
      name: "Czytanie",
      image: "📚".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Rozwój",
          color: .random
        )
      ]
    ),
    Activity(
      id: UUID(4),
      name: "Praca",
      image: "💼".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Work",
          color: .random
        )
      ]
    ),
    Activity(
      id: UUID(5),
      name: "Sauna",
      image: "🧖".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Odpoczynek",
          color: .random
        )
      ]
    ),
    Activity(
      id: UUID(6),
      name: "Drzemka",
      image: "🛏️".emojiToImage(size: 70.0).pngData(),
      tags: [
        Tag(
          name: "Odpoczynek",
          color: .random
        )
      ]
    )
  ]
}
