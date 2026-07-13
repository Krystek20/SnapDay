import SwiftUI
import Models

public struct ListItemView: View {

  public enum Size {
    case small
    case medium
  }

  // MARK: - Environment

  @Environment(\.actionHandler) private var actionHandler

  // MARK: - Properties

  @Binding private var item: ListItem
  @FocusState private var focus: String?
  private let size: Size
  private let action: ((ListItemAction) -> Void)?
  private let customTrailingView: AnyView?

  private var imageSize: (size: CGFloat, cornerRadius: CGFloat) {
    switch size {
    case .small:
      (20.0, 10.0)
    case .medium:
      (30.0, 15.0)
    }
  }

  private var fontSize: (titleSize: CGFloat, subtitleSize: CGFloat) {
    switch size {
    case .small:
      (12.0, 10.0)
    case .medium:
      (14.0, 12.0)
    }
  }

  private var trailingSpacing: Double {
    switch size {
    case .small:
      5.0
    case .medium:
      10.0
    }
  }

  private var padding: EdgeInsets {
    switch size {
    case .small:
      EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
    case .medium:
      item.iconType != .empty || !item.subtitle.isEmpty
      ? EdgeInsets(top: 10.0, leading: 10.0, bottom: 10.0, trailing: 10.0)
      : EdgeInsets(top: 12.5, leading: 10.0, bottom: 12.5, trailing: 10.0)
    }
  }

  // MARK: - Initialization

  public init(
    item: Binding<ListItem>,
    size: Size = .medium,
    action: ((ListItemAction) -> Void)? = nil
  ) {
    self._item = item
    self.size = size
    self.action = action
    self.customTrailingView = nil
  }

  public init(
    item: ListItem,
    size: Size = .medium,
    action: ((ListItemAction) -> Void)? = nil
  ) {
    self._item = .constant(item)
    self.size = size
    self.action = action
    self.customTrailingView = nil
  }

  public init(
    item: ListItem,
    size: Size = .medium,
    @ViewBuilder customTrailingView: () -> some View
  ) {
    self._item = .constant(item)
    self.size = size
    self.action = nil
    self.customTrailingView = AnyView(customTrailingView())
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: .zero) {
      VStack(alignment: .leading, spacing: 5.0) {
        headerView
        HStack(spacing: 5.0) {
          ImageView(
            type: item.iconType,
            size: imageSize.size,
            cornerRadius: imageSize.cornerRadius
          )
          leftView
          Spacer(minLength: 5.0)
          rightView
            .padding(.trailing, 5.0)
        }
      }
      .padding(padding)
      .padding(.leading, item.isSubtask ? 10.0 : .zero)

      divider
    }
    .bind($item.focus, to: $focus)
  }

  @ViewBuilder
  private var divider: some View {
    switch item.divider {
    case .full:
      Divider()
        .padding(.leading, .zero)
    case .aligned:
      Divider()
        .padding(.leading, padding.leading)
    case .indented:
      Divider()
        .padding(.leading, 20.0)
    case .none:
      EmptyView()
    }
  }

  @ViewBuilder
  private var leftView: some View {
    switch item.fieldType {
    case .text:
      VStack(alignment: .leading, spacing: 2.0) {
        titleView
        switch size {
        case .small:
          EmptyView()
        case .medium:
          subtitleView
        }
      }
    case .textEdit:
      textField
    }
  }

  @ViewBuilder
  private var rightView: some View {
    switch item.fieldType {
    case .text:
      HStack(spacing: trailingSpacing) {
        progressView
        HStack(spacing: 5.0) {
          ForEach(item.displayedIcons, content: listItem)
          HStack(spacing: -5.0) {
            ForEach(item.participants, content: participantItem)
          }
        }
        trailingView
      }
    case .textEdit:
      if !item.title.isEmpty {
        Button(String(localized: "Cancel", bundle: .module), action: {
          action?(.newItemForm(.cancelled))
        })
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
      }
    }
  }

  @ViewBuilder
  private var headerView: some View {
    if let headerItem = item.headerItem {
      HStack(alignment: .top, spacing: 5.0) {
        Text(String(localized: headerItem.title, bundle: .module))
          .font(.system(size: 12.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)
        Spacer()
        if let trailingAction = headerItem.trailingAction {
          Button(String(localized: trailingAction.title, bundle: .module)) {
            actionHandler?(trailingAction.identifier, item)
          }
          .foregroundStyle(Color.actionBlue)
          .font(.system(size: 12.0, weight: .semibold))
          .padding(.trailing, 5.0)
        }
      }
    }
  }

  private var titleView: some View {
    Text(item.title)
      .font(.system(size: fontSize.titleSize, weight: .medium))
      .lineLimit(1)
      .foregroundStyle(Color.sectionText)
      .customStrikethrough(item.isStrikethrough, color: .sectionText)
  }

  @ViewBuilder
  private var subtitleView: some View {
    if !item.subtitle.isEmpty {
      Text(item.subtitle)
        .font(.system(size: fontSize.subtitleSize, weight: .regular))
        .lineLimit(1)
        .foregroundStyle(Color.sectionText)
        .customStrikethrough(item.isStrikethrough, color: .sectionText)
    }
  }

  @ViewBuilder
  private var progressView: some View {
    switch item.progress {
    case .none:
      EmptyView()
    case .line(let value, let total):
      ProgressView(value: value, total: total)
          .frame(width: 30.0)
          .tint(.sectionText)
    }
  }

  @ViewBuilder
  private var textField: some View {
    TextField("", text: $item.title)
      .font(.system(size: 14.0, weight: .medium))
      .foregroundStyle(Color.sectionText)
      .submitLabel(.done)
      .focused($focus, equals: item.id)
      .onSubmit {
        action?(.newItemForm(.submitted))
      }
  }

  private func listItem(icon: ListItem.Icon) -> some View {
    Image(systemName: icon.rawValue)
      .iconable(color: Color.sectionText)
  }

  private func participantItem(_ participant: ListItem.Participant) -> some View {
    Text(participant.initials)
      .font(.system(size: 15.0 / 2.0, weight: .bold))
      .foregroundColor(participant.backgroundColor.isLight() ? .sectionText : .pureWhite)
      .frame(width: 15.0, height: 15.0)
      .background(Circle().fill(participant.backgroundColor.color))
  }

  @ViewBuilder
  private var trailingView: some View {
    if let customTrailingView {
      customTrailingView
    } else {
      switch item.trailing {
      case .none:
        EmptyView()
      case .row(let rowItems):
        rowItemsView(rowItems)
      case .menu(let menuItems):
        menuItemsView(menuItems)
      }
    }
  }

  private func rowItemsView(_ items: [ListTrailingRowItem]) -> some View {
    HStack(spacing: .zero) {
      ForEach(items) { rowItem in
        Button {
          actionHandler?(rowItem.id, item)
          action?(.rowAction(ListItemAction.RowParameters(actionId: rowItem.id, itemId: item.id)))
        } label: {
          Image(systemName: rowItem.imageName)
            .iconable(color: rowItem.color)
            .padding(.all, 5.0)
        }
      }
    }
  }

  private func menuItemsView(_ items: [ListTrailingMenuItem]) -> some View {
    TrailingIcon.moreIcon
      .overlay {
        Menu {
          ForEach(items) { item in
            menuItemView(item)
          }
        } label: {
          Color.clear
            .frame(width: 30.0, height: 30.0)
        }
      }
  }

  @ViewBuilder
  private func menuItemView(_ menuItem: ListTrailingMenuItem) -> some View {
    if menuItem.subitems.isEmpty {
      Button(
        action: {
          actionHandler?(menuItem.id, item)

          action?(
            .menuAction(
              menuParameters: ListItemAction.MenuParameters(actionId: menuItem.id, itemId: item.id, parentId: item.parentId),
              submenuParameters: nil
            )
          )
        },
        label: {
          Text(menuItem.title)
          Image(systemName: menuItem.imageName)
        }
      )
    } else {
      Menu {
        ForEach(menuItem.subitems) { subitem in
          Button(
            action: {
              actionHandler?(menuItem.id, item)

              action?(
                .menuAction(
                  menuParameters: ListItemAction.MenuParameters(actionId: menuItem.id, itemId: item.id, parentId: item.parentId),
                  submenuParameters: ListItemAction.SubmenuParameters(actionId: subitem.actionId, itemId: subitem.itemId)
                )
              )
            },
            label: {
              Text(subitem.title)
              Image(systemName: subitem.imageName)
            }
          )
        }
      } label: {
        Text(menuItem.title)
        Image(systemName: menuItem.imageName)
      }
    }
  }
}

/// Strikethrough on widget is broken
fileprivate extension View {
  @ViewBuilder
  func customStrikethrough(_ value: Bool, color: Color, lineHeight: CGFloat = 1) -> some View {
    if value {
      modifier(Strikethrough(color: color, lineHeight: lineHeight))
    } else {
      self
    }
  }
}

fileprivate struct Strikethrough: ViewModifier {
  let color: Color
  let lineHeight: CGFloat

  func body(content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geometry in
          Rectangle()
            .fill(color)
            .frame(height: lineHeight)
            .position(
              x: geometry.size.width / 2.0,
              y: geometry.size.height / 2.0
            )
        }
          .allowsHitTesting(false)
      )
  }
}
