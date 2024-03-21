import SwiftUI
import Resources
import Models

public struct FormMarkerField<Marker: MarkerProtocol & Identifiable>: View {

  // MARK: - Properties

  private let title: String
  private let placeholder: String
  private let existingMarkersTitle: String
  private let markers: [Marker]
  private let existingMarkers: [Marker]
  private let newMarker: Binding<String>
  private let onSubmit: () -> Void
  private let addedMarkerTapped: (Marker) -> Void
  private let existingMarkerTapped: (Marker) -> Void
  private let removeMarker: (Marker) -> Void

  // MARK: - Initialization

  public init(
    title: String,
    placeholder: String = "",
    existingMarkersTitle: String = "",
    markers: [Marker],
    existingMarkers: [Marker],
    newMarker: Binding<String>,
    onSubmit: @escaping () -> Void,
    addedMarkerTapped: @escaping (Marker) -> Void,
    existingMarkerTapped: @escaping (Marker) -> Void,
    removeMarker: @escaping (Marker) -> Void
  ) {
    self.title = title
    self.placeholder = placeholder
    self.existingMarkersTitle = existingMarkersTitle
    self.markers = markers
    self.existingMarkers = existingMarkers
    self.newMarker = newMarker
    self.onSubmit = onSubmit
    self.addedMarkerTapped = addedMarkerTapped
    self.existingMarkerTapped = existingMarkerTapped
    self.removeMarker = removeMarker
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      Text(title)
        .formTitleTextStyle
      addedMarkersView
      newMarkerField
      existingMarkersViewIfNotEmpty
    }
    .formBackgroundModifier()
  }

  @ViewBuilder
  private var addedMarkersView: some View {
    if !markers.isEmpty {
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(markers) { marker in
            MarkerView(marker: marker)
              .onTapGesture {
                addedMarkerTapped(marker)
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

  private var newMarkerField: some View {
    TextField(placeholder, text: newMarker)
      .font(.system(size: 16.0, weight: .regular))
      .foregroundStyle(Color.standardText)
      .padding(.top, markers.isEmpty ? 2.0 : .zero)
      .onSubmit { onSubmit() }
  }

  @ViewBuilder
  private var existingMarkersViewIfNotEmpty: some View {
    if !existingMarkers.isEmpty {
      VStack(alignment: .leading) {
        Text(existingMarkersTitle)
          .formTitleTextStyle
        suggestedMarkersView
      }
      .padding(.top, 10.0)
    }
  }

  private var suggestedMarkersView: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(existingMarkers) { marker in
          MarkerView(marker: marker)
            .onTapGesture {
              existingMarkerTapped(marker)
            }
            .contextMenu {
              Button(
                action: {
                  removeMarker(marker)
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
