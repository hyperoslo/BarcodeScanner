import UIKit

/// View controller used for showing info text and loading animation.
public final class MessageViewController: UIViewController {
  // Image tint color for all the states, except for `.notFound`.
  public var regularTintColor: UIColor = .black
  // Image tint color for `.notFound` state.
  public var errorTintColor: UIColor = .red
  // Customizable state messages.
  public var messages = StateMessageProvider()

  // MARK: - UI properties

  /// Text label.
  public private(set) lazy var textLabel: UILabel = self.makeTextLabel()
  /// Info image view.
  public private(set) lazy var imageView: UIImageView = self.makeImageView()
  /// Border view.
  public private(set) lazy var borderView: UIView = self.makeBorderView()

  /// Blur effect view.
  private lazy var blurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .extraLight))
  // Constraints that are activated when the view is used as a footer.
  private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
  // Constraints that are activated when the view is used for loading animation and error messages.
  private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()

  var status = Status(state: .scanning) {
    didSet {
      handleStatusUpdate()
    }
  }

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(blurView)
    blurView.contentView.addSubviews(textLabel, imageView, borderView)
    handleStatusUpdate()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    blurView.frame = view.bounds
  }

  // MARK: - Animations

  /// Animates blur and border view.
  func animateLoading() {
    animate(blurStyle: .light)
    animate(borderViewAngle: CGFloat(Double.pi/2))
  }

  /**
   Animates blur to make pulsating effect.

   - Parameter style: The current blur style.
   */
    private func animate(blurStyle: UIBlurEffect.Style) {
    guard status.state == .processing else { return }

    UIView.animate(
      withDuration: 2.0,
      delay: 0.5,
      options: [.beginFromCurrentState],
      animations: ({ [weak self] in
        self?.blurView.effect = UIBlurEffect(style: blurStyle)
      }),
      completion: ({ [weak self] _ in
        self?.animate(blurStyle: blurStyle == .light ? .extraLight : .light)
      }))
  }

  /**
   Animates border view with a given angle.

   - Parameter angle: Rotation angle.
   */
  private func animate(borderViewAngle: CGFloat) {
    guard status.state == .processing else {
      borderView.transform = .identity
      return
    }

    UIView.animate(
      withDuration: 0.8,
      delay: 0.5,
      usingSpringWithDamping: 0.6,
      initialSpringVelocity: 1.0,
      options: [.beginFromCurrentState],
      animations: ({ [weak self] in
        self?.borderView.transform = CGAffineTransform(rotationAngle: borderViewAngle)
      }),
      completion: ({ [weak self] _ in
        self?.animate(borderViewAngle: borderViewAngle + CGFloat(Double.pi / 2))
      }))
  }

  // MARK: - State handling

  private func handleStatusUpdate() {
    borderView.isHidden = true
    borderView.layer.removeAllAnimations()
    textLabel.text = status.text ?? messages.makeText(for: status.state)

    switch status.state {
    case .scanning, .unauthorized:
      textLabel.numberOfLines = 3
      textLabel.textAlignment = .left
      imageView.tintColor = regularTintColor
    case .processing:
      textLabel.numberOfLines = 10
      textLabel.textAlignment = .center
      borderView.isHidden = false
      imageView.tintColor = regularTintColor
    case .notFound:
      textLabel.font = UIFont.boldSystemFont(ofSize: 16)
      textLabel.numberOfLines = 10
      textLabel.textAlignment = .center
      imageView.tintColor = errorTintColor
    }

    if status.state == .scanning || status.state == .unauthorized {
      expandedConstraints.deactivate()
      collapsedConstraints.activate()
    } else {
      collapsedConstraints.deactivate()
      expandedConstraints.activate()
    }
  }
}

// MARK: - Subviews factory

private extension MessageViewController {
  func makeTextLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .black
    label.numberOfLines = 3
    label.font = UIFont.boldSystemFont(ofSize: 14)
    return label
  }

  func makeImageView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = imageNamed("info").withRenderingMode(.alwaysTemplate)
    imageView.tintColor = .black
    return imageView
  }

  func makeBorderView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 10
    view.layer.borderColor = UIColor.black.cgColor
    return view
  }
}

// MARK: - Layout

extension MessageViewController {
  private func makeExpandedConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 10
    let borderSize: CGFloat = 51

    return [
      imageView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor, constant: -60),
      imageView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 30),
      imageView.heightAnchor.constraint(equalToConstant: 27),

      textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
      textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

      borderView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -12),
      borderView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
      borderView.widthAnchor.constraint(equalToConstant: borderSize),
      borderView.heightAnchor.constraint(equalToConstant: borderSize)
    ]
  }

  private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 10
    var constraints = [
      imageView.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 18),
      imageView.widthAnchor.constraint(equalToConstant: 30),
      imageView.heightAnchor.constraint(equalToConstant: 27),

      textLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -3),
      textLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10)
    ]

    if #available(iOS 11.0, *) {
      constraints += [
        imageView.leadingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.leadingAnchor,
          constant: padding
        ),
        textLabel.trailingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.trailingAnchor,
          constant: -padding
        )
      ]
    } else {
      constraints += [
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
        textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
      ]
    }

    return constraints
  }
}
