import AVFoundation

/// Service used to check authorization status of the capture device.
final class VideoPermissionService {
  enum Error: Swift.Error {
    case notAuthorizedToUseCamera
  }

  // MARK: - Authorization

  /// Checks authorization status of the capture device.
  func checkPersmission(completion: @escaping (Error?) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      completion(nil)
    case .notDetermined:
      askForPermissions(completion)
    default:
      completion(Error.notAuthorizedToUseCamera)
    }
  }

  /// Asks for permission to use video.
  private func askForPermissions(_ completion: @escaping (Error?) -> Void) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      DispatchQueue.main.async {
        guard granted else {
          completion(Error.notAuthorizedToUseCamera)
          return
        }
        completion(nil)
      }
    }
  }
}
