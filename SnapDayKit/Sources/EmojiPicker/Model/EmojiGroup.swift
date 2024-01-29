import Foundation

public struct EmojiGroup: Decodable, Equatable, Identifiable {
  public var id: String { name }
  let name: String
  let subgroups: [EmojiSubgroup]
}

extension [EmojiGroup] {
  func filter(by text: String) -> [EmojiGroup] {
    reduce(into: [EmojiGroup](), { result, group in
      let subgroups = group.subgroups.reduce(into: [EmojiSubgroup](), { result, subgroup in
        let items = subgroup.items.filter { $0.description.contains(text.lowercased()) }
        guard !items.isEmpty else { return }
        result.append(EmojiSubgroup(name: subgroup.name, items: items))
      })
      guard !subgroups.isEmpty else { return }
      result.append(EmojiGroup(name: group.name, subgroups: subgroups))
    })
  }
}
