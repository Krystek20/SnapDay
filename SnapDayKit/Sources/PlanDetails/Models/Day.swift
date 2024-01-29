import Models

extension Day {
  var formattedDate: String {
    date.formatted(date: .complete, time: .omitted)
  }
}
