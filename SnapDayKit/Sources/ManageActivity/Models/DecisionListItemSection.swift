import struct UiComponents.ListItem

struct DecisionListItemSection: Identifiable {
  var id: String { listItems.map(\.id).joined() }
  let listItems: [DecisionListItem]
}

struct DecisionListItem: Identifiable {
  var id: String { listItem.id }
  let listItem: ListItem
  let indent: Int
  let disabled: Bool
}

extension [DecisionListItemSection] {
  init(decisions: [Decision]) {
    self = decisions.map { decisition in
      DecisionListItemSection(listItems: [DecisionListItem](for: decisition))
    }
  }
}

extension [DecisionListItem] {
  init(
    for decision: Decision,
    indent: Int = .zero,
    isLast: Bool = true,
    isFirst: Bool = true,
    parentAccepted: Bool = true
  ) {
    self = switch decision {
    case .leaf(let parameters):
      [
        DecisionListItem(
          listItem: ListItem(
            configuration: ListItemConfiguration(
              identifier: parameters.action.actionId,
              decisionType: parameters.decisionType,
              showDivider: !isLast,
              showAcceptAll: false,
              showTrailingView: parameters.result == nil
            )
          ),
          indent: indent,
          disabled: !isFirst && !parentAccepted
        )
      ]
    case .chain(let parameters, let next):
      [
        DecisionListItem(
          listItem: ListItem(
            configuration: ListItemConfiguration(
              identifier: parameters.action.actionId,
              decisionType: parameters.decisionType,
              showDivider: !next.isEmpty,
              showAcceptAll: next.all.contains(where: { $0.parameters.result == nil }),
              showTrailingView: parameters.result == nil
            )
          ),
          indent: indent,
          disabled: !isFirst && !parentAccepted
        )
      ] + next.map { decision in
        [DecisionListItem](
          for: decision,
          indent: indent + 1,
          isLast: next.last == decision,
          isFirst: false,
          parentAccepted: parameters.result == .accepted
        )
      }
      .joined()
    }
  }
}
