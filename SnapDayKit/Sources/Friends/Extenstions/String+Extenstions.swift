import Foundation

extension String {
  var isValidEmail: Bool {
      let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
      let emailPred = NSPredicate(format:"SELF MATCHES %@", regex)
      return emailPred.evaluate(with: self)
  }

  var isValidPhone: Bool {
    let regex = "^(?:[0-9] ?){6,14}[0-9]$"
    let phoneTest = NSPredicate(format: "SELF MATCHES %@", regex)
    return phoneTest.evaluate(with: self)
  }
}
