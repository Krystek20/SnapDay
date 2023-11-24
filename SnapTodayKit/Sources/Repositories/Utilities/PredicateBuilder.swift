import Foundation

@resultBuilder
public struct PredicateBuilder {
  public static func buildBlock(_ components: [NSPredicate]...) -> [NSPredicate] {
    components.flatMap { $0 }
  }

  public static func buildEither(first component: NSPredicate) -> NSPredicate {
    component
  }

  public static func buildEither(second component: NSPredicate) -> NSPredicate {
    component
  }

  public static func buildArray(_ components: [NSPredicate]) -> [NSPredicate] {
    components
  }

  public static func buildExpression(_ expression: NSPredicate) -> [NSPredicate] {
    [expression]
  }

  public static func buildExpression(_ expression: [NSPredicate]) -> [NSPredicate] {
    expression
  }

  public static func buildOptional(_ component: [NSPredicate]?) -> [NSPredicate] {
    component ?? []
  }
}
