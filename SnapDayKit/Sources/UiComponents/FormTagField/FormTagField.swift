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
  private let existingTagTapped: (Tag) -> Void

  // MARK: - Initialization

  public init(
    title: String,
    placeholder: String = "",
    existingTagsTitle: String = "",
    tags: [Tag],
    existingTags: [Tag],
    newTag: Binding<String>,
    onSubmit: @escaping () -> Void,
    existingTagTapped: @escaping (Tag) -> Void
  ) {
    self.title = title
    self.placeholder = placeholder
    self.existingTagsTitle = existingTagsTitle
    self.tags = tags
    self.existingTags = existingTags
    self.newTag = newTag
    self.onSubmit = onSubmit
    self.existingTagTapped = existingTagTapped
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
          ForEach(tags, content: tagView)
        }
        .measureHeight
      }
      .scrollIndicators(.hidden)
      .adjustHeight(height: 20.0)
      .padding(.vertical, 10.0)
    }
  }

  private func tagView(_ tag: Tag) -> some View {
    Text(tag.name)
      .padding(
        EdgeInsets(
          top: 2.0,
          leading: 5.0,
          bottom: 2.0,
          trailing: 5.0
        )
      )
      .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 14.0))
      .foregroundStyle(tagForegroundStyle(tag))
      .background(tagBackground(tag))
  }

  private func tagForegroundStyle(_ tag: Tag) -> some ShapeStyle {
    tag.rgbColor.isLight()
    ? Colors.slateHaze.swiftUIColor
    : Colors.pureWhite.swiftUIColor
  }

  private func tagBackground(_ tag: Tag) -> some View {
    tag.rgbColor.color
      .clipShape(RoundedRectangle(cornerRadius: 3.0))
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
          tagView(tag)
            .onTapGesture {
              existingTagTapped(tag)
            }
        }
      }
      .measureHeight
    }
    .scrollIndicators(.hidden)
    .adjustHeight(height: 20.0)
  }
}
