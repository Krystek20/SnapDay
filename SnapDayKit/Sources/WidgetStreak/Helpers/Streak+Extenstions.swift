import Utilities
import Resources

extension Streak? {
  var image: Images {
    guard let self else { return .strike0 }
    return self.image
  }
}

extension Streak {
  var image: Images {
    switch current {
    case .zero:
        .strike0
    case 1...3:
        .strike1_3
    case 4...7:
        .strike4_7
    case 8...14:
        .strike8_14
    case 15...30:
        .strike15_30
    case 31...:
        .strike31
    default:
        .strike0
    }
  }
}
