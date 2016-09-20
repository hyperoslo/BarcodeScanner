import UIKit

/**
 Info view is an overlay with loading and error messages.
 */
class InfoView: UIVisualEffectView {

  /// Text label.
  lazy var label: UILabel = {
    let label = UILabel()
    label.numberOfLines = 2

    return label
  }()

  /// Info image view.
  lazy var imageView: UIImageView = {
    let image = imageNamed("info").withRenderingMode(.alwaysTemplate)
    let imageView = UIImageView(image: image)

    return imageView
  }()

  /// Border view.
  lazy var borderView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.clear
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 10

    return view
  }()

  /**
   The current info view status mode.
   */
  var status: Status = Status(.scanning) {
    didSet {
      setupFrames()

      let stateStyles = status.state.styles

      label.text = status.text
      label.textColor = Info.textColor
      label.font = stateStyles.font
      label.textAlignment = stateStyles.alignment
      imageView.tintColor = stateStyles.tint
      borderView.layer.borderColor = stateStyles.tint.cgColor

      if status.state != .processing {
        borderView.isHidden = true
        borderView.layer.removeAllAnimations()
      }
    }
  }

  // MARK: - Initialization

  /**
   Creates a new instance of `InfoView`.
   */
  init() {
    let blurEffect = UIBlurEffect(style: .extraLight)
    super.init(effect: blurEffect)

    [label, imageView, borderView].forEach {
      addSubview($0)
    }

    status = Status(.scanning)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  /**
   Sets up frames of subviews.
   */
  func setupFrames() {
    let padding: CGFloat = 10
    let labelHeight: CGFloat = 40
    let imageSize = CGSize(width: 30, height: 27)
    let borderSize: CGFloat = 51

    if status.state != .processing && status.state != .notFound {
      imageView.frame = CGRect(
        x: padding,
        y: (frame.height - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height)

      label.frame = CGRect(
        x: imageView.frame.maxX + padding,
        y: 0,
        width: frame.width - imageView.frame.maxX - 2 * padding,
        height: frame.height)
    } else {
      imageView.frame = CGRect(
        x: (frame.width - imageSize.width) / 2,
        y: (frame.height - imageSize.height) / 2 - 60,
        width: imageSize.width,
        height: imageSize.height)

      label.frame = CGRect(
        x: padding,
        y: imageView.frame.maxY + 14,
        width: frame.width - 2 * padding,
        height: labelHeight)
    }

    borderView.frame = CGRect(
      x: (frame.width - borderSize) / 2,
      y: imageView.frame.minY - 12,
      width: borderSize,
      height: borderSize)
  }

  // MARK: - Animations

  /**
   Animates blur and border view.
   */
  func animateLoading() {
    borderView.isHidden = false

    animateBlur(.light)
    animateBorderView(CGFloat(M_PI_2))
  }

  /**
   Animates blur to make pulsating effect.

   - Parameter style: The current blur style.
   */
  func animateBlur(_ style: UIBlurEffectStyle) {
    guard status.state == .processing else { return }

    UIView.animate(withDuration: 2.0, delay: 0.5, options: [.beginFromCurrentState],
      animations: {
        self.effect = UIBlurEffect(style: style)
      }, completion: { _ in
        self.animateBlur(style == .light ? .extraLight : .light)
    })
  }

  /**
   Animates border view with a given angle.

   - Parameter angle: Rotation angle.
   */
  func animateBorderView(_ angle: CGFloat) {
    guard status.state == .processing else {
      borderView.transform = CGAffineTransform.identity
      return
    }

    UIView.animate(withDuration: 0.8,
      delay: 0.5, usingSpringWithDamping: 0.6,
      initialSpringVelocity: 1.0,
      options: [.beginFromCurrentState],
      animations: {
        self.borderView.transform = CGAffineTransform(rotationAngle: angle)
      }, completion: { _ in
        self.animateBorderView(angle + CGFloat(M_PI_2))
    })
  }
}
