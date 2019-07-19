//
//  String+Extensions.swift
//  BarcodeScanner-iOS
//
//  Created by Carlos Alcala on 7/18/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import Foundation

extension String {
    /**
     Returns localized string using localization resource bundle.
     - Parameter name: localization name.
     - Returns: localized text.
     */

    var localizedString: String {
        if let path = Bundle(for: BarcodeScannerViewController.self).resourcePath,
            let bundle = Bundle(path: path + "/Localized.bundle") {
            return NSLocalizedString(self, tableName: "", bundle: bundle, value: "", comment: "")
        }
        return self
    }

    var localized: String {
        if let path = Bundle(for: BarcodeScannerViewController.self).resourcePath,
            let resourceBundle = Bundle(path: path + "/Localized.bundle") {
            return resourceBundle.localizedString(forKey: self, value: nil, table: "Localizable")
        }
        return self
    }
}
