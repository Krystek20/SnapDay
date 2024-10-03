// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "SnapDayKit",
    defaultLocalization: "en",
    platforms: [
      .iOS(.v16)
    ],
    products: products,
    dependencies: packageDependencies,
    targets: targets
)

@ProductsBuilder
private var products: [Product] {
  Module.application
  Module.eveningSummary
  Module.dayActivityReminder
  Module.widgetActivityList
  Module.previews
}

@PackageDependenciesBuilder
private var packageDependencies: [Package.Dependency] {
  Module.composableArchitecture
}

@TargetsBuilder
private var targets: [Target] {
  TargetParamenters(module: .application, dependencies: sceneDependecies + [.onboarding, .dashboard, .reports, .developerTools])
  TargetParamenters(module: .dashboard, dependencies: sceneDependecies + [.activityList, .dayActivityForm, .calendarPicker])
  TargetParamenters(module: .activityList, dependencies: sceneDependecies + [.dayActivityForm])
  TargetParamenters(module: .markerForm, dependencies: sceneDependecies)
  TargetParamenters(module: .dayActivityForm, dependencies: sceneDependecies + [.markerForm, .emojiPicker])
  TargetParamenters(module: .reports, dependencies: sceneDependecies + [.selectableList])
  TargetParamenters(module: .selectableList, dependencies: sceneDependecies)
  TargetParamenters(module: .eveningSummary, dependencies: sceneDependecies)
  TargetParamenters(module: .dayActivityReminder, dependencies: sceneDependecies)
  TargetParamenters(module: .widgetActivityList, dependencies: sceneDependecies)
  TargetParamenters(module: .onboarding, dependencies: sceneDependecies)
  TargetParamenters(module: .developerTools, dependencies: sceneDependecies)
  TargetParamenters(module: .emojiPicker, dependencies: [.common, .uiComponents, .resources])
  TargetParamenters(module: .calendarPicker, dependencies: [.common, .uiComponents, .resources])
  TargetParamenters(module: .utilities, dependencies: [.models, .repositories, .composableArchitecture])
  TargetParamenters(module: .repositories, dependencies: [.common, .models, .composableArchitecture])
  TargetParamenters(module: .common, dependencies: [.composableArchitecture])
  TargetParamenters(module: .models, dependencies: [.common])
  TargetParamenters(module: .previews, dependencies: [.application])
  TargetParamenters(module: .uiComponents, dependencies: [.resources, .composableArchitecture, .utilities])
  TargetParamenters(module: .resources)
}

private var sceneDependecies: [Module] {
  [
    .common,
    .models,
    .repositories,
    .uiComponents,
    .resources,
    .utilities
  ]
}

// MARK: - Library Name

private enum Module: String {
  case application
  case dashboard
  case activityList
  case markerForm
  case dayActivityForm
  case emojiPicker
  case calendarPicker
  case reports
  case selectableList
  case eveningSummary
  case widgetActivityList
  case dayActivityReminder
  case onboarding
  case developerTools
  case utilities
  case repositories
  case common
  case models
  case previews
  case uiComponents
  case resources
  case composableArchitecture

  var name: String {
    rawValue.capitalizingFirstLetter
  }

  var dependency: Target.Dependency? {
    switch self {
    case .composableArchitecture:
      .product(name: name, package: "swift-composable-architecture")
    default:
      .byName(name: name)
    }
  }

  var products: [Product] {
    let mainProduct = Product.library(
      name: name,
      targets: [name]
    )
    return [mainProduct]
  }

  var packageDependecies: [Package.Dependency]? {
    switch self {
    case .composableArchitecture:
      [.package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.9.2")]
    default:
      nil
    }
  }

  var targetConfiguration: [ModuleTargetConfiguration] {
    switch self {
    case .composableArchitecture:
      []
    case .previews, .uiComponents, .resources, .developerTools:
      [.source]
    default:
      [.source, .tests]
    }
  }

  var resources: [Resource] {
    []
  }
}

// MARK: - Product

@resultBuilder
private struct ProductsBuilder {
  static func buildBlock(_ components: Module...) -> [Product] {
    components.reduce(into: [Product](), { result, module in
      result.append(contentsOf: module.products)
    })
  }
}

// MARK: - PackageDependencies

@resultBuilder
private struct PackageDependenciesBuilder {
  static func buildBlock(_ components: Module...) -> [Package.Dependency] {
    components.reduce(into: [Package.Dependency](), { result, module in
      guard let packageDependecies = module.packageDependecies else { return }
      result.append(contentsOf: packageDependecies)
    })
  }
}

// MARK: - Targets

private enum ModuleTargetConfiguration {
  case source
  case tests
}

private struct TargetParamenters {
  let module: Module
  var dependencies: [Module] = []
}

@resultBuilder
private struct TargetsBuilder {
  static func buildBlock(_ components: TargetParamenters...) -> [Target] {
    components.reduce(into: [Target]()) { partialResult, paramenters in
      if paramenters.module.targetConfiguration.contains(.source) {
        partialResult.append(Target.target(paramenters.module, dependencies: paramenters.dependencies))
      }
      if paramenters.module.targetConfiguration.contains(.tests) {
        partialResult.append(Target.testTarget(paramenters.module, dependencies: paramenters.dependencies))
      }
    }
  }
}

private extension Target {
  static func target(_ name: Module, dependencies: [Module]) -> Target {
    .target(
      name: name.name,
      dependencies: dependencies.compactMap(\.dependency),
      resources: name.resources
    )
  }

  static func testTarget(_ name: Module, dependencies: [Module]) -> Target {
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
