import Foundation

struct EmojiProvider {

  enum EmojiProviderError: Error {
    case urlNotFound
  }

  // MARK: - Properties

  private let bundle: Bundle
  private let decoder: JSONDecoder

  var emoji: [EmojiGroup] {
    get throws {
      guard let url = bundle.url(forResource: "emoji", withExtension: "json") else {
        throw EmojiProviderError.urlNotFound
      }
      let data = try Data(contentsOf: url)
      return try decoder.decode([EmojiGroup].self, from: data)
    }
  }

  // MARK: - Initialization

  init(bundle: Bundle = .module) {
    self.bundle = bundle
    self.decoder = JSONDecoder()
    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
}
