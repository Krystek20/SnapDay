public enum PlansLoadState: Equatable {
  case idle
  case loading
  case loaded
  case failed(String)
}
