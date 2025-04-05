//
//  LocalizationManager.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()

    private init() {}

    func localizedString(forKey key: String, language: String? = nil) -> String {
        if let language = language {
            // Tạm thời đặt ngôn ngữ cụ thể nếu cần
            let bundle = Bundle.main.path(forResource: language, ofType: "lproj").flatMap { Bundle(path: $0) } ?? .main
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        return NSLocalizedString(key, comment: "")
    }
}
