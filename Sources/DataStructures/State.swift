import UIKit

// MARK: - State

/// Barcode scanner state.
enum State {
  case scanning
  case processing
  case unauthorized
  case notFound
}

/// State message provider.
public struct StateMessageProvider {
  public var scanningText = "INFO_DESCRIPTION_TEXT".localized
  public var processingText = "INFO_LOADING_TITLE".localized
  public var unathorizedText = "ASK_FOR_PERMISSION_TEXT".localized
  public var notFoundText = "NO_PRODUCT_ERROR_TITLE".localized

  func makeText(for state: State) -> String {
    switch state {
    case .scanning:
      return scanningText
    case .processing:
      return processingText
    case .unauthorized:
      return unathorizedText
    case .notFound:
      return notFoundText
    }
  }
}

// MARK: - Status

/// Status is a holder of the current state with a few additional configuration properties.
struct Status {
  /// The current state.
  let state: State
  /// Flag to enable/disable animation.
  let animated: Bool
  /// Text that overrides a text from the state.
  let text: String?

  /**
   Creates a new instance of `Status`.
   - Parameter state: State value.
   - Parameter animated: Flag to enable/disable animation.
   - Parameter text: Text that overrides a text from the state.
   */
  init(state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text
  }
}
