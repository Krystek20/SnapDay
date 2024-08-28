import Foundation
import Common

public struct Icon: Identifiable, Equatable, Hashable, Decodable, Encodable {

  private enum CodingKeys: String, CodingKey {
    case id
    case data
    case emoji
  }

  // MARK: - Properties

  public let id: UUID
  public var data: Data?

  // MARK: - Initialization

  public init(
    id: UUID,
    data: Data? = nil
  ) {
    self.id = id
    self.data = data
  }

  public init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(UUID.self, forKey: .id)
    let emoji = try values.decodeIfPresent(String.self, forKey: .emoji)
    data = try values.decodeIfPresent(Data.self, forKey: .data) ?? emoji?.emojiToImage(size: 140.0).pngData()
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(data, forKey: .data)
  }
}
