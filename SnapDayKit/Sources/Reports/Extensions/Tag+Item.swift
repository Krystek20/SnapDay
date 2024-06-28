import SelectableList
import Models

extension Tag {
  var item: Item {
    Item(
      id: id,
      name: name,
      leftItem: .color(rgbColor)
    )
  }
}

extension [Tag] {
  var items: [Item] {
    map(\.item)
  }
}
