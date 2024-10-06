import SwiftUI
import Resources

public struct ComplateAlertViewConfiguration: Equatable {
  let image: Images
  let title: String
  let subtitle: String
  let confirmButtonTitle: String
  let cancelButtonTitle: String
  var remainingTime: TimeInterval?

  public init(
    image: Images,
    title: String,
    subtitle: String,
    confirmButtonTitle: String,
    cancelButtonTitle: String,
    remainingTime: TimeInterval? = nil
  ) {
    self.image = image
    self.title = title
    self.subtitle = subtitle
    self.confirmButtonTitle = confirmButtonTitle
    self.cancelButtonTitle = cancelButtonTitle
    self.remainingTime = remainingTime
  }
}

public struct ComplateAlertView: View {

  private let configuration: ComplateAlertViewConfiguration
  private var confirmButtonTapped: () -> Void
  private var cancelButtonTapped: () -> Void
  @State private var progress: TimeInterval

  public init(
    configuration: ComplateAlertViewConfiguration,
    confirmButtonTapped: @escaping () -> Void,
    cancelButtonTapped: @escaping () -> Void
  ) {
    self.configuration = configuration
    self.progress = configuration.remainingTime ?? .zero
    self.confirmButtonTapped = confirmButtonTapped
    self.cancelButtonTapped = cancelButtonTapped
  }

  public var body: some View {
    VStack(spacing: .zero) {
      content
      progressView
    }
    .clipShape(RoundedRectangle(cornerRadius: 10.0))
    .background(background)
  }

  private var content: some View {
    VStack(spacing: 10.0) {
      HStack(alignment: .top, spacing: 10.0) {
        Image(from: configuration.image)
          .resizable()
          .frame(width: 50.0, height: 50.0)
        VStack(alignment: .leading) {
          Text(configuration.title)
            .font(.system(size: 14.0, weight: .medium))
            .foregroundStyle(Color.standardText)
          Text(configuration.subtitle)
            .font(.system(size: 12.0, weight: .regular))
            .foregroundStyle(Color.standardText)
        }
        Spacer()
      }
      HStack {
        Spacer()
        Button(configuration.confirmButtonTitle, action: confirmButtonTapped)
          .buttonStyle(PrimaryButtonStyle(height: .small))
        Spacer()
        Button(configuration.cancelButtonTitle, action: cancelButtonTapped)
          .buttonStyle(CancelButtonStyle())
        Spacer()
      }
    }
    .padding(.all, 10.0)
  }

  @ViewBuilder
  private var progressView: some View {
    if let remainingTime = configuration.remainingTime {
      ProgressView(value: progress, total: remainingTime)
        .tint(.actionBlue)
        .task {
          while progress > .zero {
            try? await Task.sleep(for: .milliseconds(20))
            var nextValue = progress - 0.01
            if nextValue < .zero {
              nextValue = .zero
            }
            withAnimation(.linear(duration: 0.02)) {
              progress = nextValue
            }
          }
          Task { @MainActor in
            cancelButtonTapped()
          }
        }
    }
  }

  private var background: some View {
    RoundedRectangle(cornerRadius: 10.0)
      .fill(Color.formBackground)
      .shadow(color: Color.standardText.opacity(0.15), radius: 5.0, x: .zero, y: .zero)
  }
}
