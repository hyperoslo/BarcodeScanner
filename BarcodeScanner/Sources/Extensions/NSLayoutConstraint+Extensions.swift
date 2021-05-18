import UIKit

extension NSLayoutConstraint {
  /// A helper function to activate layout constraints.
  static func activate(_ constraints: NSLayoutConstraint? ...) {
    for case let constraint in constraints {
      guard let constraint = constraint else {
        continue
      }

      (constraint.firstItem as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
      constraint.isActive = true
    }
  }
}

extension Array where Element: NSLayoutConstraint {
  func activate() {
    forEach {
      if !$0.isActive {
        $0.isActive = true
      }
    }
  }

  func deactivate() {
    forEach {
      if $0.isActive {
        $0.isActive = false
      }
    }
  }
}
