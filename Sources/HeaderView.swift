import UIKit

protocol HeaderViewDelegate: class {
  func headerViewDidPressClose(_ hederView: HeaderView)
}

/**
 Header view that simulates a navigation bar.
 */
class HeaderView: UIView {

  /// Title label.
  lazy var label: UILabel = {
    let label = UILabel()
    label.backgroundColor = UIColor.white
    label.text = Title.text
    label.font = Title.font
    label.textColor = Title.color
    label.numberOfLines = 1
    label.textAlignment = .center

    return label
  }()

  /// Close button.
  lazy var button: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle(CloseButton.text, for: UIControlState())
    button.titleLabel?.font = CloseButton.font
    button.tintColor = CloseButton.color
    button.addTarget(self, action: #selector(buttonDidPress), for: .touchUpInside)

    return button
  }()

  /// Header view delegate.
  weak var delegate: HeaderViewDelegate?

  // MARK: - Initialization

  /**
   Creates a new instance of `HeaderView`.

   - Parameter frame: View frame.
   */
  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.white

    [label, button].forEach {
      addSubview($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat = 8
    let labelHeight: CGFloat = 40

    button.sizeToFit()

    button.frame.origin = CGPoint(x: 15,
      y: ((frame.height - button.frame.height) / 2) + padding)

    label.frame = CGRect(
      x: 0, y: ((frame.height - labelHeight) / 2) + padding,
      width: frame.width, height: labelHeight)
  }

  // MARK: - Actions

  /**
   Close button action handler.
   */
  func buttonDidPress() {
    delegate?.headerViewDidPressClose(self)
  }
}
