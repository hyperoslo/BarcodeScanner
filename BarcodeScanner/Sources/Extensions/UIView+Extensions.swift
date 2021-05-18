import UIKit

extension UIView {
  /// A helper function to add multiple subviews.
  func addSubviews(_ subviews: UIView...) {
    subviews.forEach {
      addSubview($0)
    }
  }
}
