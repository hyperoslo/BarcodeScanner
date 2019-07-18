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

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
