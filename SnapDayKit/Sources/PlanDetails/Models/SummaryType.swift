import Foundation

enum SummaryType {
  case circle(progress: Double)
  case chart(points: [Double], expectedPoints: Int)
}
