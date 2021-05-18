import UIKit
import AVFoundation

/**
 Returns image with a given name from the resource bundle.
 - Parameter name: Image name.
 - Returns: An image.
 */
func imageNamed(_ name: String) -> UIImage {
  let traitCollection = UITraitCollection(displayScale: 3)
    let bundlePath = Bundle(for: BarcodeScannerViewController.self).path(forResource: "Images", ofType: "bundle")
    let bundle = Bundle(path: bundlePath!)
    guard let image = UIImage(named: name, in: bundle!, compatibleWith: traitCollection) else {
    return UIImage()
  }

  return image
}

/**
 Returns localized string using localization resource bundle.
 - Parameter name: Image name.
 - Returns: An image.
 */
func localizedString(_ key: String) -> String {
    let bundlePath = Bundle(for: BarcodeScannerViewController.self).path(forResource: "Localization", ofType: "bundle")
    let bundle = Bundle(path: bundlePath!)
    return NSLocalizedString(key, bundle: bundle!, comment: key)
}

/// Checks if the app is running in Simulator.
var isSimulatorRunning: Bool = {
  #if swift(>=4.1)
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  #else
    #if (arch(i386) || arch(x86_64)) && os(iOS)
      return true
    #else
      return false
    #endif
  #endif
}()
