import UIKit
import BarcodeScanner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  lazy var viewController: ViewController = {
    let controller = ViewController()
    return controller
  }()

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = viewController
    window?.makeKeyAndVisible()

    return true
  }
}
