import UIKit

// MARK: - Status

/**
 Status is a holder of the current state
 with a few additional configuration properties.
 */
struct Status {
  /// The current state.
  let state: State

  /// A flag to enable/disable animation.
  let animated: Bool

  /// A text that overrides a text from the state.
  let text: String

  /**
   Creates a new instance of `Status`.

   - Parameter state: A state.
   - Parameter animated: A flag to enable/disable animation.
   - Parameter text: A text that overrides a text from the state.
   */
  init(_ state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text ?? state.text
  }
}

// MARK: - State.

/**
 Barcode scanner state.
 */
enum State {
  case scanning, processing, unauthorized, notFound

  typealias Styles = (tint: UIColor, font: UIFont, alignment: NSTextAlignment)

  /// State message.
  var text: String {
    let string: String

    switch self {
    case .scanning:
      string = Info.text
    case .processing:
      string = Info.loadingText
    case .unauthorized:
      string = Info.settingsText
    case .notFound:
      string = Info.notFoundText
    }

    return string
  }

  /// State styles.
  var styles: Styles {
    let styles: Styles

    switch self {
    case .scanning:
      styles = (
        tint: Info.tint,
        font: Info.font,
        alignment: .left
      )
    case .processing:
      styles = (
        tint: Info.loadingTint,
        font: Info.loadingFont,
        alignment: .center
      )
    case .unauthorized:
      styles = (
        tint: Info.tint,
        font: Info.font,
        alignment: .left
      )
    case .notFound:
      styles = (
        tint: Info.notFoundTint,
        font: Info.loadingFont,
        alignment: .center
      )
    }

    return styles
  }
}
