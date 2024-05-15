![BarcodeScanner](https://github.com/hyperoslo/BarcodeScanner/blob/master/Art/BarcodeScannerPresentation.png)

[![CI Status](http://img.shields.io/travis/hyperoslo/BarcodeScanner.svg?style=flat)](https://travis-ci.org/hyperoslo/BarcodeScanner)
[![Version](https://img.shields.io/cocoapods/v/BarcodeScanner.svg?style=flat)](http://cocoadocs.org/docsets/BarcodeScanner)
![Swift](https://img.shields.io/badge/%20in-swift%204.0-orange.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/BarcodeScanner.svg?style=flat)](http://cocoadocs.org/docsets/BarcodeScanner)
[![Platform](https://img.shields.io/cocoapods/p/BarcodeScanner.svg?style=flat)](http://cocoadocs.org/docsets/BarcodeScanner)

## Description

**BarcodeScanner** is a simple and beautiful wrapper around the camera with
barcode capturing functionality and a great user experience.

- [x] Barcode scanning.
- [x] State modes: scanning, processing, unauthorized, not found.
- [x] Handling of camera authorization status.
- [x] Animated focus view and custom loading indicator.
- [x] Torch mode switch.
- [x] Customizable colors, informational and error messages.
- [x] No external dependencies.
- [x] [Demo project](https://github.com/hyperoslo/BarcodeScanner/tree/master/Example/BarcodeScannerExample).

## Table of Contents

<img src="https://github.com/hyperoslo/BarcodeScanner/blob/master/Art/BarcodeScannerIcon.png" alt="BarcodeScanner Icon" width="190" height="190" align="right" />

* [Usage](#usage)
  * [Controller](#controller)
  * [Delegates](#delegates)
  * [Actions](#actions)
  * [Customization](#customization)
* [Installation](#installation)
* [Author](#author)
* [Contributing](#contributing)
* [License](#license)

## Usage

### Controller

To start capturing just instantiate `BarcodeScannerViewController`, set needed
delegates and present it:

```swift
let viewController = BarcodeScannerViewController()
viewController.codeDelegate = self
viewController.errorDelegate = self
viewController.dismissalDelegate = self

present(viewController, animated: true, completion: nil)
```

<div align="center">
<img src="https://github.com/hyperoslo/BarcodeScanner/blob/master/Art/ExampleScanning.png" alt="BarcodeScanner scanning" width="270" height="480" />
</div><br/>

You can also push `BarcodeScannerViewController` to your navigation stack:

```swift
let viewController = BarcodeScannerViewController()
viewController.codeDelegate = self

navigationController?.pushViewController(viewController, animated: true)
```

### Delegates

**Code delegate**

Use `BarcodeScannerCodeDelegate` when you want to get the captured code back.

```swift
extension ViewController: BarcodeScannerCodeDelegate {
  func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
    print(code)
    controller.reset()
  }
}
```

**Error delegate**

Use `BarcodeScannerErrorDelegate` when you want to handle session errors.
```swift
extension ViewController: BarcodeScannerErrorDelegate {
  func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
    print(error)
  }
}
```

**Dismissal delegate**

Use `BarcodeScannerDismissalDelegate` to handle "Close button" tap.
**Please note** that `BarcodeScannerViewController` doesn't dismiss itself if
it was presented initially.

```swift
extension ViewController: BarcodeScannerDismissalDelegate {
  func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
```

### Actions

When the code is captured `BarcodeScannerViewController` switches to the processing
mode:

<div align="center">
<img src="https://github.com/hyperoslo/BarcodeScanner/blob/master/Art/ExampleLoading.png" alt="BarcodeScanner loading" width="270" height="480" />
</div><br/>

While the user sees a nice loading animation you can perform some
background task, for example make a network request to fetch product info based
on the code. When the task is done you have 3 options to proceed:

1. Dismiss `BarcodeScannerViewController` and show your results.

```swift
func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
 // Code processing
 controller.dismiss(animated: true, completion: nil)
}
```

2. Show an error message and switch back to the scanning mode (for example,
when there is no product found with a given barcode in your database):

<div align="center">
<img src="https://github.com/hyperoslo/BarcodeScanner/blob/master/Art/ExampleError.png" alt="BarcodeScanner error" width="270" height="480" />
</div><br/>

```swift
func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
 // Code processing
 controller.resetWithError(message: "Error message")
 // If message is not provided the default message will be used instead.
}
```

3. Reset the controller to the scanning mode (with or without animation):

 ```swift
 func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
   // Code processing
   controller.reset(animated: true)
 }
 ```

If you want to do continuous barcode scanning just set the `isOneTimeSearch`
property on your `BarcodeScannerViewController` instance to `false`.

### Customization

We styled **BarcodeScanner** to make it look nice, but you can always use public
properties or inheritance to customize its appearance.

**Header**

```swift
let viewController = BarcodeScannerViewController()
viewController.headerViewController.titleLabel.text = "Scan barcode"
viewController.headerViewController.closeButton.tintColor = .red
```

**Please note** that `HeaderViewController` is visible only when
`BarcodeScannerViewController` is being presented.

**Footer and messages**

```swift
let viewController = BarcodeScannerViewController()
viewController.messageViewController.regularTintColor = .black
viewController.messageViewController.errorTintColor = .red
viewController.messageViewController.textLabel.textColor = .black
```

**Camera**
```swift
let viewController = BarcodeScannerViewController()
// Change focus view style
viewController.cameraViewController.barCodeFocusViewType = .animated
// Show camera position button
viewController.cameraViewController.showsCameraButton = true
// Set the initial camera position
viewController.cameraViewController.initialCameraPosition = .front // Default is .back
// Set settings button text
let title = NSAttributedString(
  string: "Settings",
  attributes: [.font: UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.white]
)
viewController.cameraViewController.settingButton.setAttributedTitle(title, for: UIControlState())
```

**Metadata**
```swift
// Add extra metadata object type
let viewController = BarcodeScannerViewController()
viewController.metadata.append(AVMetadataObject.ObjectType.qr)
```

## Installation

**BarcodeScanner** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BarcodeScanner'
```

Don't forget to set a `Privacy - Camera Usage Description` in your Info.plist file, else the app will crash with a SIGBART. 

In order to quickly try the demo project of a **BarcodeScanner** just run
`pod try BarcodeScanner` in your terminal.

**BarcodeScanner** is also available through [Carthage](https://github.com/Carthage/Carthage).
To install just write into your Cartfile:

```ruby
github "hyperoslo/BarcodeScanner"
```

To install **BarcodeScanner** manually just download and drop `Sources` and
`Images` folders in your project.

## Author

Hyper Interaktiv AS, ios@hyper.no

## Contributing

We would love you to contribute to **BarcodeScanner**, check the [CONTRIBUTING](https://github.com/hyperoslo/BarcodeScanner/blob/master/CONTRIBUTING.md) file for more info.

## License

**BarcodeScanner** is available under the MIT license. See the [LICENSE](https://github.com/hyperoslo/BarcodeScanner/blob/master/LICENSE.md) file for more info.
