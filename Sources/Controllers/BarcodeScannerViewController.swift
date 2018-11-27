import UIKit
import AVFoundation

// MARK: - Delegates

/// Delegate to handle the captured code.
public protocol BarcodeScannerCodeDelegate: class {
  func scanner(
    _ controller: BarcodeScannerViewController,
    didCaptureCode code: String,
    type: String
  )
}

/// Delegate to report errors.
public protocol BarcodeScannerErrorDelegate: class {
  func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error)
}

/// Delegate to dismiss barcode scanner when the close button has been pressed.
public protocol BarcodeScannerDismissalDelegate: class {
  func scannerDidDismiss(_ controller: BarcodeScannerViewController)
}

// MARK: - Controller

/**
 Barcode scanner controller with 4 sates:
 - Scanning mode
 - Processing animation
 - Unauthorized mode
 - Not found error message
 */
open class BarcodeScannerViewController: UIViewController {
  private static let footerHeight: CGFloat = 75

  // MARK: - Public properties

  /// Delegate to handle the captured code.
  public weak var codeDelegate: BarcodeScannerCodeDelegate?
  /// Delegate to report errors.
  public weak var errorDelegate: BarcodeScannerErrorDelegate?
  /// Delegate to dismiss barcode scanner when the close button has been pressed.
  public weak var dismissalDelegate: BarcodeScannerDismissalDelegate?

  /// When the flag is set to `true` controller returns a captured code
  /// and waits for the next reset action.
  public var isOneTimeSearch = true

  /// `AVCaptureMetadataOutput` metadata object types.
  public var metadata = AVMetadataObject.ObjectType.barcodeScannerMetadata {
    didSet {
      cameraViewController.metadata = metadata
    }
  }

  // MARK: - Private properties

  /// Flag to lock session from capturing.
  private var locked = false
  /// Flag to check if layout constraints has been activated.
  private var constraintsActivated = false
  /// Flag to check if view controller is currently on screen
  private var isVisible = false

  // MARK: - UI

  // Title label and close button.
  public private(set) lazy var headerViewController: HeaderViewController = .init()
  /// Information view with description label.
  public private(set) lazy var messageViewController: MessageViewController = .init()
  /// Camera view with custom buttons.
  public private(set) lazy var cameraViewController: CameraViewController = .init()

  // Constraints that are activated when the view is used as a footer.
  private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
  // Constraints that are activated when the view is used for loading animation and error messages.
  private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()

  private var messageView: UIView {
    return messageViewController.view
  }

  /// The current controller's status mode.
  private var status: Status = Status(state: .scanning) {
    didSet {
      changeStatus(from: oldValue, to: status)
    }
  }

  // MARK: - View lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.black

    add(childViewController: messageViewController)
    messageView.translatesAutoresizingMaskIntoConstraints = false
    collapsedConstraints.activate()

    cameraViewController.metadata = metadata
    cameraViewController.delegate = self
    add(childViewController: cameraViewController)

    view.bringSubviewToFront(messageView)
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupCameraConstraints()
    isVisible = true
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    isVisible = false
  }

  // MARK: - State handling

  /**
   Shows error message and goes back to the scanning mode.
   - Parameter errorMessage: Error message that overrides the message from the config.
   */
  public func resetWithError(message: String? = nil) {
    status = Status(state: .notFound, text: message)
  }

  /**
   Resets the controller to the scanning mode.
   - Parameter animated: Flag to show scanner with or without animation.
   */
  public func reset(animated: Bool = true) {
    status = Status(state: .scanning, animated: animated)
  }

  private func changeStatus(from oldValue: Status, to newValue: Status) {
    guard newValue.state != .notFound else {
      messageViewController.status = newValue
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
        self.status = Status(state: .scanning)
      }
      return
    }

    let animatedTransition = newValue.state == .processing
      || oldValue.state == .processing
      || oldValue.state == .notFound
    let duration = newValue.animated && animatedTransition ? 0.5 : 0.0
    let delayReset = oldValue.state == .processing || oldValue.state == .notFound

    if !delayReset {
      resetState()
    }

    if newValue.state != .processing {
      expandedConstraints.deactivate()
      collapsedConstraints.activate()
    } else {
      collapsedConstraints.deactivate()
      expandedConstraints.activate()
    }

    messageViewController.status = newValue

    UIView.animate(
      withDuration: duration,
      animations: ({
        self.view.layoutIfNeeded()
      }),
      completion: ({ [weak self] _ in
        if delayReset {
          self?.resetState()
        }

        self?.messageView.layer.removeAllAnimations()
        if self?.status.state == .processing {
          self?.messageViewController.animateLoading()
        }
      }))
  }

  /// Resets the current state.
  private func resetState() {
    locked = status.state == .processing && isOneTimeSearch
    if status.state == .scanning {
      cameraViewController.startCapturing()
    } else {
      cameraViewController.stopCapturing()
    }
  }

  // MARK: - Animations

  /**
   Simulates flash animation.
   - Parameter processing: Flag to set the current state to `.processing`.
   */
  private func animateFlash(whenProcessing: Bool = false) {
    let flashView = UIView(frame: view.bounds)
    flashView.backgroundColor = UIColor.white
    flashView.alpha = 1

    view.addSubview(flashView)
    view.bringSubviewToFront(flashView)

    UIView.animate(
      withDuration: 0.2,
      animations: ({
        flashView.alpha = 0.0
      }),
      completion: ({ [weak self] _ in
        flashView.removeFromSuperview()

        if whenProcessing {
          self?.status = Status(state: .processing)
        }
      }))
  }
}

// MARK: - Layout

private extension BarcodeScannerViewController {
  private func setupCameraConstraints() {
    guard !constraintsActivated else {
      return
    }

    constraintsActivated = true
    let cameraView = cameraViewController.view!

    NSLayoutConstraint.activate(
      cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      cameraView.bottomAnchor.constraint(
        equalTo: view.bottomAnchor,
        constant: -BarcodeScannerViewController.footerHeight
      )
    )

    if navigationController != nil {
      cameraView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    } else {
      headerViewController.delegate = self
      add(childViewController: headerViewController)

      let headerView = headerViewController.view!

      NSLayoutConstraint.activate(
        headerView.topAnchor.constraint(equalTo: view.topAnchor),
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        headerView.bottomAnchor.constraint(equalTo: headerViewController.navigationBar.bottomAnchor),
        cameraView.topAnchor.constraint(equalTo: headerView.bottomAnchor)
      )
    }
  }

  private func makeExpandedConstraints() -> [NSLayoutConstraint] {
    return [
      messageView.topAnchor.constraint(equalTo: view.topAnchor),
      messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      messageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ]
  }

  private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
    return [
      messageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      messageView.heightAnchor.constraint(
        equalToConstant: BarcodeScannerViewController.footerHeight
      )
    ]
  }
}

// MARK: - HeaderViewControllerDelegate

extension BarcodeScannerViewController: HeaderViewControllerDelegate {
  func headerViewControllerDidTapCloseButton(_ controller: HeaderViewController) {
    dismissalDelegate?.scannerDidDismiss(self)
  }
}

// MARK: - CameraViewControllerDelegate

extension BarcodeScannerViewController: CameraViewControllerDelegate {
  func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController) {
    status = Status(state: .scanning)
  }

  func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController) {
    status = Status(state: .unauthorized)
  }

  func cameraViewController(_ controller: CameraViewController, didReceiveError error: Error) {
    errorDelegate?.scanner(self, didReceiveError: error)
  }

  func cameraViewControllerDidTapSettingsButton(_ controller: CameraViewController) {
    DispatchQueue.main.async {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
      }
    }
  }

  func cameraViewController(_ controller: CameraViewController,
                            didOutput metadataObjects: [AVMetadataObject]) {
    guard !locked && isVisible else { return }
    guard !metadataObjects.isEmpty else { return }

    guard
      let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
      var code = metadataObj.stringValue,
      metadata.contains(metadataObj.type)
      else { return }

    if isOneTimeSearch {
      locked = true
    }

    var rawType = metadataObj.type.rawValue

    // UPC-A is an EAN-13 barcode with a zero prefix.
    // See: https://stackoverflow.com/questions/22767584/ios7-barcode-scanner-api-adds-a-zero-to-upca-barcode-format
    if metadataObj.type == AVMetadataObject.ObjectType.ean13 && code.hasPrefix("0") {
      code = String(code.dropFirst())
      rawType = AVMetadataObject.ObjectType.upca.rawValue
    }

    codeDelegate?.scanner(self, didCaptureCode: code, type: rawType)
    animateFlash(whenProcessing: isOneTimeSearch)
  }
}
