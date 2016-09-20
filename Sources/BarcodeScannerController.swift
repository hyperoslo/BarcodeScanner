import UIKit
import AVFoundation

// MARK: - Delegates

/// Delegate to handle the captured code.
public protocol BarcodeScannerCodeDelegate: class {
  func barcodeScanner(_ controller: BarcodeScannerController, didCapturedCode code: String, type: String)
}

/// Delegate to report errors.
public protocol BarcodeScannerErrorDelegate: class {
  func barcodeScanner(_ controller: BarcodeScannerController, didReceiveError error: Error)
}

/// Delegate to dismiss barcode scanner when the close button has been pressed.
public protocol BarcodeScannerDismissalDelegate: class {
  func barcodeScannerDidDismiss(_ controller: BarcodeScannerController)
}

// MARK: - Controller

/**
 Barcode scanner controller with 4 sates:
 - Scanning mode
 - Processing animation
 - Unauthorized mode
 - Not found error message
 */
open class BarcodeScannerController: UIViewController {

  /// Video capture device.
  lazy var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

  /// Capture session.
  lazy var captureSession: AVCaptureSession = AVCaptureSession()

  /// Header view with title and close button.
  lazy var headerView: HeaderView = HeaderView()

  /// Information view with description label.
  lazy var infoView: InfoView = InfoView()

  /// Button to change torch mode.
  lazy var flashButton: UIButton = { [unowned self] in
    let button = UIButton(type: .custom)
    button.addTarget(self, action: #selector(flashButtonDidPress), for: .touchUpInside)

    return button
    }()

  /// Animated focus view.
  lazy var focusView: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.white.cgColor
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 5
    view.layer.shadowColor = UIColor.white.cgColor
    view.layer.shadowRadius = 10.0
    view.layer.shadowOpacity = 0.9
    view.layer.shadowOffset = CGSize.zero
    view.layer.masksToBounds = false

    return view
  }()

  /// Button that opens settings to allow camera usage.
  lazy var settingsButton: UIButton = { [unowned self] in
    let button = UIButton(type: .system)
    let title = NSAttributedString(string: SettingsButton.text,
      attributes: [
        NSFontAttributeName : SettingsButton.font,
        NSForegroundColorAttributeName : SettingsButton.color,
      ])

    button.setAttributedTitle(title, for: UIControlState())
    button.sizeToFit()
    button.addTarget(self, action: #selector(settingsButtonDidPress), for: .touchUpInside)

    return button
    }()

  /// Video preview layer.
  lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer?.videoGravity = AVLayerVideoGravityResize

    return videoPreviewLayer!
    }()

  /// The current controller's status mode.
  var status: Status = Status(.scanning) {
    didSet {
      let duration = status.animated &&
        (status.state == .processing
          || oldValue.state == .processing
          || oldValue.state == .notFound
        ) ? 0.5 : 0.0

      guard status.state != .notFound else {
        infoView.status = status

        DispatchQueue.main.asyncAfter(
          deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.status = Status(.scanning)
        }

        return
      }

      let delayReset = oldValue.state == .processing || oldValue.state == .notFound

      if !delayReset {
        resetState()
      }

      UIView.animate(withDuration: duration,
        animations: {
          self.infoView.frame = self.infoFrame
          self.infoView.status = self.status
        },
        completion: { _ in
          if delayReset {
            self.resetState()
          }

          self.infoView.layer.removeAllAnimations()
          if self.status.state == .processing {
            self.infoView.animateLoading()
          }
      })
    }
  }

  /// The current torch mode on the capture device.
  var torchMode: TorchMode = .off {
    didSet {
      guard captureDevice.hasFlash else { return }

      do {
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = torchMode.captureTorchMode
        captureDevice.unlockForConfiguration()
      } catch {}

      flashButton.setImage(torchMode.image, for: UIControlState())
    }
  }

  /// Calculated frame for the info view.
  var infoFrame: CGRect {
    let height = status.state != .processing ? 75 : view.bounds.height
    return CGRect(x: 0, y: view.bounds.height - height,
      width: view.bounds.width, height: height)
  }

  /// When the flag is set to `true` controller returns a captured code
  /// and waits for the next reset action.
  open var oneTimeSearch = true

  /// Delegate to handle the captured code.
  open weak var codeDelegate: BarcodeScannerCodeDelegate?

  /// Delegate to report errors.
  open weak var errorDelegate: BarcodeScannerErrorDelegate?

  /// Delegate to dismiss barcode scanner when the close button has been pressed.
  open weak var dismissalDelegate: BarcodeScannerDismissalDelegate?

  /// Flag to lock session from capturing.
  var locked = false

  // MARK: - Initialization

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - View lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.black
    view.layer.addSublayer(videoPreviewLayer)

    [infoView, headerView, settingsButton, flashButton, focusView].forEach {
      view.addSubview($0)
      view.bringSubview(toFront: $0)
    }

    torchMode = .off
    focusView.isHidden = true
    headerView.delegate = self

    setupCamera()

    NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
      name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    setupFrames()
    infoView.setupFrames()
    headerView.isHidden = !isBeingPresented
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    animateFocusView()
  }

  /**
   `UIApplicationWillEnterForegroundNotification` action.
   */
  func appWillEnterForeground() {
    torchMode = .off
    animateFocusView()
  }

  // MARK: - Configuration

  /**
   Sets up camera and checks for camera permissions.
   */
  func setupCamera() {
    let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)

    if authorizationStatus == .authorized {
      setupSession()
      status = Status(.scanning)
    } else if authorizationStatus == .notDetermined {
      AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
        completionHandler: { (granted: Bool) -> Void in
          DispatchQueue.main.async {
            if granted {
              self.setupSession()
            }

            self.status = granted ? Status(.scanning) : Status(.unauthorized)
          }
      })
    } else {
      status = Status(.unauthorized)
    }
  }

  /**
   Sets up capture input, output and session.
   */
  func setupSession() {
    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      errorDelegate?.barcodeScanner(self, didReceiveError: error)
    }

    let output = AVCaptureMetadataOutput()
    captureSession.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    output.metadataObjectTypes = metadata
    videoPreviewLayer.session = captureSession

    setupFrames()
  }

  // MARK: - Reset

  /**
   Shows error message and goes back to the scanning mode.

   - Parameter message: Error message that overrides the message from the config.
   */
  open func resetWithError(_ message: String? = nil) {
    status = Status(.notFound, text: message)
  }

  /**
   Resets the controller to the scanning mode.

   - Parameter animated: Flag to show scanner with or without animation.
   */
  open func reset(animated: Bool = true) {
    status = Status(.scanning, animated: animated)
  }

  /**
   Resets the current state.
   */
  func resetState() {
    let alpha: CGFloat = status.state == .scanning ? 1 : 0

    torchMode = .off
    locked = status.state == .processing && oneTimeSearch

    status.state == .scanning
      ? captureSession.startRunning()
      : captureSession.stopRunning()

    focusView.alpha = alpha
    flashButton.alpha = alpha
    settingsButton.isHidden = status.state != .unauthorized
  }

  // MARK: - Layout

  /**
   Sets frames of the subviews.
   */
  func setupFrames() {
    headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
    flashButton.frame = CGRect(x: view.frame.width - 50, y: 73, width: 37, height: 37)
    infoView.frame = infoFrame
    videoPreviewLayer.frame = view.layer.bounds

    if videoPreviewLayer.connection != nil {
      videoPreviewLayer.connection.videoOrientation = .portrait
    }

    centerSubview(focusView, size: CGSize(width: 218, height: 150))
    centerSubview(settingsButton, size: CGSize(width: 150, height: 50))
  }

  /**
   Sets a new size and center aligns subview's position.

   - Parameter subview: The subview.
   - Parameter size: A new size.
  */
  func centerSubview(_ subview: UIView, size: CGSize) {
    subview.frame = CGRect(
      x: (view.frame.width - size.width) / 2,
      y: (view.frame.height - size.height) / 2,
      width: size.width,
      height: size.height)
  }

  // MARK: - Orientation

  open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return .portrait
  }

  // MARK: - Animations

  /**
   Simulates flash animation.

   - Parameter processing: Flag to set the current state to `.Processing`.
   */
  func animateFlash(_ processing: Bool = false) {
    let flashView = UIView(frame: view.bounds)
    flashView.backgroundColor = UIColor.white
    flashView.alpha = 1

    view.addSubview(flashView)
    view.bringSubview(toFront: flashView)

    UIView.animate(withDuration: 0.2,
      animations: {
        flashView.alpha = 0.0
      },
      completion: { _ in
        flashView.removeFromSuperview()

        if processing {
          self.status = Status(.processing)
        }
    })
  }

  /**
   Performs focus view animation.
   */
  func animateFocusView() {
    focusView.layer.removeAllAnimations()
    focusView.isHidden = false

    setupFrames()

    UIView.animate(withDuration: 1.0, delay:0,
      options: [.repeat, .autoreverse, .beginFromCurrentState],
      animations: {
        self.centerSubview(self.focusView, size: CGSize(width: 280, height: 80))
      }, completion: nil)
  }

  // MARK: - Actions

  /**
   Opens setting to allow camera usage.
   */
  func settingsButtonDidPress() {
    DispatchQueue.main.async {
      if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.openURL(settingsURL)
      }
    }
  }

  /**
   Sets the next torch mode.
   */
  func flashButtonDidPress() {
    torchMode = torchMode.next
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerController: AVCaptureMetadataOutputObjectsDelegate {

  public func captureOutput(_ captureOutput: AVCaptureOutput!,
    didOutputMetadataObjects metadataObjects: [Any]!,
    from connection: AVCaptureConnection!) {
      guard !locked else { return }

      guard metadataObjects != nil && !metadataObjects.isEmpty else { return }

      guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
        let code = metadataObj.stringValue
        , metadata.contains(metadataObj.type) else { return }

      if oneTimeSearch {
        locked = true
      }

      animateFlash(oneTimeSearch)
      codeDelegate?.barcodeScanner(self, didCapturedCode: code, type: metadataObj.type)
  }
}

// MARK: - HeaderViewDelegate

extension BarcodeScannerController: HeaderViewDelegate {

  func headerViewDidPressClose(_ hederView: HeaderView) {
    dismissalDelegate?.barcodeScannerDidDismiss(self)
  }
}
