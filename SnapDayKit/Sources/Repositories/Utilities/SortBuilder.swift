import Foundation

@resultBuilder
public struct SortBuilder {
  public static func buildBlock(_ components: [NSSortDescriptor]...) -> [NSSortDescriptor] {
    components.flatMap { $0 }
  }

  public static func buildExpression(_ expression: NSSortDescriptor) -> [NSSortDescriptor] {
    [expression]
  }
}
