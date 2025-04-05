import Foundation
import Combine

class LocalizationViewModel: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
        }
    }
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    let supportedLanguages: [String] = ["en", "vi", "zh-Hans"]

    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode") ?? false
    }

    func localizedString(_ key: String) -> String {
        let bundlePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj")
        if let path = bundlePath, let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        return NSLocalizedString(key, comment: "")
    }

    func setLanguage(_ language: String) {
        if supportedLanguages.contains(language) {
            currentLanguage = language
        }
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
    }
}
