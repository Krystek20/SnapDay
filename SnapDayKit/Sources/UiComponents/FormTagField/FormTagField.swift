import SwiftUI
import Resources
import Models

public struct FormTagField: View {

  // MARK: - Properties

  private let title: String
  private let placeholder: String
  private let existingTagsTitle: String
  private let tags: [Tag]
  private let existingTags: [Tag]
  private let newTag: Binding<String>
  private let onSubmit: () -> Void
  private let addedTagTapped: (Tag) -> Void
  private let existingTagTapped: (Tag) -> Void
  private let removeTag: (Tag) -> Void

  // MARK: - Initialization

  public init(
    title: String,
    placeholder: String = "",
    existingTagsTitle: String = "",
    tags: [Tag],
    existingTags: [Tag],
    newTag: Binding<String>,
    onSubmit: @escaping () -> Void,
    addedTagTapped: @escaping (Tag) -> Void,
    existingTagTapped: @escaping (Tag) -> Void,
    removeTag: @escaping (Tag) -> Void
  ) {
    self.title = title
    self.placeholder = placeholder
    self.existingTagsTitle = existingTagsTitle
    self.tags = tags
    self.existingTags = existingTags
    self.newTag = newTag
    self.onSubmit = onSubmit
    self.addedTagTapped = addedTagTapped
    self.existingTagTapped = existingTagTapped
    self.removeTag = removeTag
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      Text(title)
        .formTitleTextStyle
      addedTagsView
      newTagField
      existingTagsViewIfNotEmpty
    }
    .formBackgroundModifier
  }

  @ViewBuilder
  private var addedTagsView: some View {
    if !tags.isEmpty {
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(tags) { tag in
            TagView(tag: tag)
              .onTapGesture {
                addedTagTapped(tag)
              }
          }
        }
        .measureHeight
      }
      .scrollIndicators(.hidden)
      .adjustHeight(height: 20.0)
      .padding(.vertical, 10.0)
    }
  }

  private var newTagField: some View {
    TextField(placeholder, text: newTag)
      .font(Fonts.Quicksand.medium.swiftUIFont(size: 16.0))
      .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      .padding(.top, tags.isEmpty ? 2.0 : .zero)
      .onSubmit { onSubmit() }
  }

  @ViewBuilder
  private var existingTagsViewIfNotEmpty: some View {
    if !existingTags.isEmpty {
      VStack(alignment: .leading) {
        Text(existingTagsTitle)
          .formTitleTextStyle
        suggestedTagsView
      }
      .padding(.top, 10.0)
    }
  }

  private var suggestedTagsView: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(existingTags) { tag in
          TagView(tag: tag)
            .onTapGesture {
              existingTagTapped(tag)
            }
            .contextMenu {
              Button(
                action: {
                  removeTag(tag)
                },
                label: {
                  Text("Remove", bundle: .module)
                  Image(systemName: "trash")
                }
              )
            }
        }
      }
      .measureHeight
    }
    .scrollIndicators(.hidden)
    .adjustHeight(height: 20.0)
  }
}
