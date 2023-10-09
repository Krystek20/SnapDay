// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "SnapTodayKit",
    platforms: [
      .iOS(.v16)
    ],
    products: .libraries(
      .application,
      .dashboard,
      .historyList,
      .details,
      .previews,
      .models,
      .resources,
      .uiComponents
    ),
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.2.0"),
      .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0")
    ],
    targets: .targets
      .add(.application, dependecies: [
        .composableArchitecture,
        .dashboard,
        .historyList,
        .details,
        .resources
      ])
      .add(.dashboard, dependecies: [.composableArchitecture, .resources])
      .add(.historyList, dependecies: [.composableArchitecture])
      .add(.details, dependecies: [.composableArchitecture])
      .add(.previews, dependecies: [.application], addTestTarget: false)
      .add(.models)
      .add(.uiComponents, addTestTarget: false)
      .add(.resources, dependecies: [.swiftgen], addTestTarget: false)
)

// MARK: - Library Name

private enum LibraryName: String {
  case application
  case dashboard
  case historyList
  case details
  case composableArchitecture
  case previews
  case models
  case uiComponents
  case resources
  case swiftgen

  var name: String {
    rawValue.capitalizingFirstLetter
  }

  var dependency: Target.Dependency? {
    switch self {
    case .swiftgen:
      return nil
    case .composableArchitecture:
      return .product(name: name, package: "swift-composable-architecture")
    case .application, .dashboard, .historyList, .details, .previews, .models, .uiComponents, .resources:
      return .byName(name: name)
    }
  }

  var plugin: Target.PluginUsage? {
    switch self {
    case .swiftgen:
      return .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
    case .composableArchitecture, .application, .dashboard, .historyList, .details, .previews, .models, .uiComponents, .resources:
      return nil
    }
  }

  var resources: [Resource]? {
    switch self {
    case .resources:
      return [.process("Quicksand.ttf")]
    case .composableArchitecture, .application, .dashboard, .historyList, .details, .previews, .models, .uiComponents, .swiftgen:
      return nil
    }
  }
}

// MARK: - Product

private extension [Product] {
  static func libraries(_ name: LibraryName...) -> [Product] {
    name.map(Product.library)
  }
}

private extension Product {
  static func library(_ name: LibraryName) -> Product {
    library(name: name.rawValue.capitalizingFirstLetter, targets: [name.rawValue.capitalizingFirstLetter])
  }
}

// MARK: - Target

private extension [Target] {

  static let targets = [Target]()

  func add(_ name: LibraryName, dependecies: [LibraryName] = [], addTestTarget: Bool = true) -> [Target] {
    var targets = self
    targets.append(Target.target(name, dependencies: dependecies))
    guard addTestTarget else { return targets }
    targets.append(Target.testTarget(name, dependencies: dependecies))
    return targets
  }
}

private extension Target {
  static func target(_ name: LibraryName, dependencies: [LibraryName]) -> Target {
    .target(
      name: name.name,
      dependencies: dependencies.compactMap(\.dependency),
      resources: name.resources,
      plugins: dependencies.compactMap(\.plugin)
    )
  }

  static func testTarget(_ name: LibraryName, dependencies: [LibraryName]) -> Target {
    .testTarget(
      name: name.name + "Tests",
      dependencies: (dependencies + [name]).compactMap(\.dependency)
    )
  }
}

// MARK: - Tools

private extension String {
  var capitalizingFirstLetter: String {
    let firstCharacter = prefix(1).capitalized
    let restText = dropFirst()
    return firstCharacter + restText
  }
}
