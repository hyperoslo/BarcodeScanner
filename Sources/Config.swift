import UIKit
import AVFoundation

// MARK: - Configurations

public struct Title {
  public static var text = NSLocalizedString("Scan barcode", comment: "")
  public static var font = UIFont.boldSystemFont(ofSize: 17)
  public static var color = UIColor.black
  public static var headerBackgroundColor = UIColor.white
}

public struct CloseButton {
  public static var text = NSLocalizedString("Close", comment: "")
  public static var font = UIFont.boldSystemFont(ofSize: 17)
  public static var color = UIColor.black
}

public struct SettingsButton {
  public static var text = NSLocalizedString("Settings", comment: "")
  public static var font = UIFont.boldSystemFont(ofSize: 17)
  public static var color = UIColor.white
}

public struct Info {
  public static var text = NSLocalizedString(
    "Place the barcode within the window to scan. The search will start automatically.", comment: "")
  public static var loadingText = NSLocalizedString(
    "Looking for your product...", comment: "")
  public static var notFoundText = NSLocalizedString(
    "No product found.", comment: "")
  public static var settingsText = NSLocalizedString(
    "In order to scan barcodes you have to allow camera under your settings.", comment: "")

  public static var font = UIFont.boldSystemFont(ofSize: 14)
  public static var textColor = UIColor.black
  public static var tint = UIColor.black

  public static var loadingFont = UIFont.boldSystemFont(ofSize: 16)
  public static var loadingTint = UIColor.black

  public static var notFoundTint = UIColor.red
  public static var headerBackgroundColor = UIColor.white
}

/**
 Returns image with a given name from the resource bundle.

 - Parameter name: Image name.
 - Returns: An image.
 */
func imageNamed(_ name: String) -> UIImage {
  let cls = BarcodeScannerController.self
  var bundle = Bundle(for: cls)
  let traitCollection = UITraitCollection(displayScale: 3)

  if let path = bundle.resourcePath,
    let resourceBundle = Bundle(path: path + "/BarcodeScanner.bundle") {
      bundle = resourceBundle
  }

  guard let image = UIImage(named: name, in: bundle,
    compatibleWith: traitCollection)
    else { return UIImage() }

  return image
}

/**
 `AVCaptureMetadataOutput` metadata object types.
 */
public var metadata = [
  AVMetadataObjectTypeUPCECode,
  AVMetadataObjectTypeCode39Code,
  AVMetadataObjectTypeCode39Mod43Code,
  AVMetadataObjectTypeEAN13Code,
  AVMetadataObjectTypeEAN8Code,
  AVMetadataObjectTypeCode93Code,
  AVMetadataObjectTypeCode128Code,
  AVMetadataObjectTypePDF417Code,
  AVMetadataObjectTypeQRCode,
  AVMetadataObjectTypeAztecCode
]
