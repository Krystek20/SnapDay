import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct DictationView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<DictationFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DictationFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 24.0) {
        Text("🎙️ Speak now")
          .font(.title2.bold())

        if store.transcribedText.isEmpty {
          if store.isListening {
            ProgressView()
          } else {
            Text("Your words will appear here...")
              .foregroundColor(.gray)
          }
        } else {
          Text(store.transcribedText)
            .multilineTextAlignment(.center)
        }

        Button(store.isListening ? "Stop" : "Start") {

        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
      .onAppear {
        store.send(.view(.onAppear))
      }
    }
  }
}
