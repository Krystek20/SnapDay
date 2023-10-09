import ComposableArchitecture

public struct DetailsFeature: Reducer {

  // MARK: - State & Action

  public struct State: Equatable {

    public init() { }
  }

  public enum Action: Equatable {

  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

}
