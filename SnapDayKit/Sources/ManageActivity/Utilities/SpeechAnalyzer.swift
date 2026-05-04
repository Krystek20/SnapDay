import Speech

final class SpeechAnalyzer {
  private let audioEngine = AVAudioEngine()

  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?

  private var lastSpeechTime = Date()
  private var silenceTimerTask: Task<Void, Never>?

  init() {
//    print(SFSpeechRecognizer.supportedLocales())
  }

  func start() async throws -> String {
    guard await requestAuthorization() else {
      throw NSError(domain: "SpeechAnalyzer", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Speech or microphone permission denied."
      ])
    }

    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))

    guard speechRecognizer?.isAvailable == true else {
      throw NSError(domain: "SpeechAnalyzer", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "Location is not available"
      ])
    }

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(
      onBus: .zero,
      bufferSize: 1024,
      format: recordingFormat,
      block: { [weak self] buffer, _ in
        self?.recognitionRequest?.append(buffer)
      }
    )

    audioEngine.prepare()
    try audioEngine.start()

    startSilenceWatcher()

    return try await withCheckedThrowingContinuation { [weak self] continuation in
      guard let self,
            let speechRecognizer = self.speechRecognizer,
            let recognitionRequest = self.recognitionRequest else {
        return continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 0, userInfo: nil))
      }

      var text = ""

      speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
        if let result = result {
          text = result.bestTranscription.formattedString
          self?.lastSpeechTime = Date()
        }
        if let error {
          self?.stop()
          continuation.resume(throwing: error)
        } else if result?.isFinal == true {
          self?.stop()
          continuation.resume(returning: text)
        }
      }
    }
  }

  func stop() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    silenceTimerTask?.cancel()
    silenceTimerTask = nil
  }

  private func requestAuthorization() async -> Bool {
    let speechAuthorized = await withCheckedContinuation { cont in
      SFSpeechRecognizer.requestAuthorization { status in
        cont.resume(returning: status == .authorized)
      }
    }

    let micAuthorized = await withCheckedContinuation { cont in
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        cont.resume(returning: granted)
      }
    }

    return speechAuthorized && micAuthorized
  }

  private func startSilenceWatcher() {
    lastSpeechTime = Date()

    silenceTimerTask = Task { [weak self] in
      while Date().timeIntervalSince(self?.lastSpeechTime ?? Date()) <= 3, self?.silenceTimerTask?.isCancelled == false {
        try? await Task.sleep(for: .seconds(2))
      }
      self?.stop()
    }
  }
}
