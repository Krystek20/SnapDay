import SelectableList
import Models

extension ActivityLabel {
  var item: Item {
    Item(
      id: id,
      name: name,
      leftItem: .color(rgbColor)
    )
  }
}

extension [ActivityLabel] {
  var items: [Item] {
    map(\.item)
  }
}
