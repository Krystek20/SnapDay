import TipKit

@available(iOS 17.0, *)
struct SaveActivityTip: Tip, Equatable {

  // MARK: - Paramenters

  @Parameter
  static var show: Bool = false

  // MARK: - Propertise

  let id = "SaveActivityTip"
  let title = Text("Activity Saved!", bundle: .module)
  let message: Text? = Text("Great job! Your activity has been successfully saved to your activity list. You can find it under the 'Activity List' button. From there, you can make your saved activities frequently and manage them easily. Keep up the good work!", bundle: .module)

  var rules: [Rule] {
    [
      #Rule(Self.$show) { $0 }
    ]
  }

  var options: [Option] {
    [
      Tips.MaxDisplayCount(1),
      Tips.IgnoresDisplayFrequency(true)
    ]
  }
}
