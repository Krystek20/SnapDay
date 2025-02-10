import SelectableList
import Models

extension Activity {
  var item: Item {
    Item(
      id: id.uuidString,
      name: name,
      leftItem: .icon(iconId)
    )
  }
}

extension [Activity] {
  var items: [Item] {
    map(\.item)
  }
}
