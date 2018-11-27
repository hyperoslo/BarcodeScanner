import UIKit

extension UIViewController {
  /// A helper function to add child view controller.
  func add(childViewController: UIViewController) {
    childViewController.willMove(toParent: self)
    addChild(childViewController)
    view.addSubview(childViewController.view)
    childViewController.didMove(toParent: self)
  }
}
