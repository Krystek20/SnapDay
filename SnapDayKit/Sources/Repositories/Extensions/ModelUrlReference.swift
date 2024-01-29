import Foundation

public enum ModelUrlReference {
  public static func modelUrl(name: String) throws -> URL? {
    Bundle.module.coreDataModelUrl(name: name)
  }
}
