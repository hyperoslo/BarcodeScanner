import UIKit
import AVFoundation

/**
 Wrapper around `AVCaptureTorchMode`.
 */
public enum TorchMode {
  case on, off

  /// Returns the next torch mode.
  var next: TorchMode {
    let result: TorchMode

    switch self {
    case .on:
      result = .off
    case .off:
      result = .on
    }

    return result
  }

  /// Torch mode image.
  var image: UIImage {
    let result: UIImage

    switch self {
    case .on:
      result = imageNamed("flashOn")
    case .off:
      result = imageNamed("flashOff")
    }

    return result
  }

  /// Returns `AVCaptureTorchMode` value.
  var captureTorchMode: AVCaptureTorchMode {
    let result: AVCaptureTorchMode

    switch self {
    case .on:
      result = .on
    case .off:
      result = .off
    }

    return result
  }
}
