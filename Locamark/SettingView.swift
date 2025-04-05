//
//  SettingView.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import MessageUI

struct SettingView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @Binding var isPresented: Bool
    @State private var showDocumentPicker = false
    @State private var csvFileURL: URL?
    @State private var isImporting = false
    @State private var showImportAlert = false
    @State private var importMessage: String?
    @State private var showMailComposer = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(localizationViewModel.localizedString("General"))) {
                    Toggle(localizationViewModel.localizedString("Dark Mode"), isOn: $localizationViewModel.isDarkMode)
                        .accessibilityLabel(localizationViewModel.localizedString("Toggle Dark Mode"))
                    Picker(localizationViewModel.localizedString("Language"), selection: $localizationViewModel.currentLanguage) {
                        ForEach(localizationViewModel.supportedLanguages, id: \.self) { language in
                            Text(languageName(for: language))
                                .tag(language)
                        }
                    }
                    .accessibilityLabel(localizationViewModel.localizedString("Select Language"))
                }

                Section(header: Text(localizationViewModel.localizedString("Data"))) {
                    Button(action: { exportLocationsToCSV() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 16))
                            Text(localizationViewModel.localizedString("Export sao lưu"))
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel(localizationViewModel.localizedString("Export Backup"))
                    
                    Button(action: {
                        isImporting = true
                        csvFileURL = nil
                        showDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 16))
                            Text(localizationViewModel.localizedString("Import sao lưu"))
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel(localizationViewModel.localizedString("Import Backup"))
                }

                Section(header: Text(localizationViewModel.localizedString("Support"))) {
                    Button(action: { showMailComposer = true }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 16))
                            Text(localizationViewModel.localizedString("Send Feedback"))
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel(localizationViewModel.localizedString("Send Feedback"))
                    
                    Button(action: { openPrivacyPolicy() }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 16))
                            Text(localizationViewModel.localizedString("Privacy Policy"))
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel(localizationViewModel.localizedString("View Privacy Policy"))
                }
            }
            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 600 : .infinity)
            .navigationTitle(localizationViewModel.localizedString("Settings"))
            .navigationBarItems(leading: Button(action: { isPresented = false }) {
                Text(localizationViewModel.localizedString("Close"))
                    .foregroundColor(.blue)
            }
            .accessibilityLabel(localizationViewModel.localizedString("Close Settings")))
            .preferredColorScheme(localizationViewModel.isDarkMode ? .dark : .light)
            .sheet(isPresented: $showDocumentPicker, onDismiss: {
                if let url = csvFileURL, !isImporting {
                    try? FileManager.default.removeItem(at: url) // Xóa tệp tạm sau export
                }
            }) {
                DocumentPicker(
                    url: csvFileURL ?? URL(fileURLWithPath: ""),
                    isImporting: isImporting,
                    localizationViewModel: localizationViewModel,
                    locationViewModel: locationViewModel,
                    onImportCompleted: { success, message in
                        importMessage = message
                        showImportAlert = true
                        showDocumentPicker = false
                    }
                )
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(isPresented: $showMailComposer)
            }
            .alert(isPresented: $showImportAlert) {
                Alert(
                    title: Text(localizationViewModel.localizedString("Import Result")),
                    message: Text(importMessage ?? ""),
                    dismissButton: .default(Text(localizationViewModel.localizedString("OK")))
                )
            }
        }
    }

    private func exportLocationsToCSV() {
        let locations = locationViewModel.locations
        guard !locations.isEmpty else {
            importMessage = localizationViewModel.localizedString("No locations to export")
            showImportAlert = true
            return
        }

        var csvString = "ID,Latitude,Longitude,Timestamp,LocationName,Category\n"
        for location in locations {
            let id = location.id.uuidString
            let latitude = String(location.latitude)
            let longitude = String(location.longitude)
            let timestamp = location.timestamp?.formatted(date: .numeric, time: .shortened) ?? ""
            let locationName = location.locationName ?? ""
            let category = location.category ?? "other"

            let formattedLocationName = locationName.contains(",") ? "\"\(locationName)\"" : locationName
            let formattedCategory = category.contains(",") ? "\"\(category)\"" : category

            let row = "\(id),\(latitude),\(longitude),\(timestamp),\(formattedLocationName),\(formattedCategory)\n"
            csvString.append(row)
        }

        do {
            let fileManager = FileManager.default
            let tempDirectory = fileManager.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent("locations_\(Date().formatted(.iso8601)).csv")

            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Exported CSV to: \(fileURL.path)")
            self.csvFileURL = fileURL
            self.isImporting = false
            self.showDocumentPicker = true
        } catch {
            print("Error exporting CSV: \(error.localizedDescription)")
            importMessage = localizationViewModel.localizedString("Error exporting file: ") + error.localizedDescription
            showImportAlert = true
        }
    }

    private func languageName(for code: String) -> String {
        let locale = Locale(identifier: code)
        switch code {
        case "en": return "English"
        case "vi": return "Tiếng Việt"
        case "zh-Hans": return "中文 (简体)"
        default: return locale.localizedString(forIdentifier: code) ?? code
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.locamark.com/privacy-policy") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// DocumentPicker để xử lý xuất/nhập file CSV
struct DocumentPicker: UIViewControllerRepresentable {
    let url: URL
    let isImporting: Bool
    let localizationViewModel: LocalizationViewModel
    let locationViewModel: LocationViewModel
    var onImportCompleted: (Bool, String?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        if isImporting {
            print("Creating picker for import")
            let csvType = UTType.commaSeparatedText
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [csvType], asCopy: true)
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
        } else {
            print("Creating picker for export")
            picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if parent.isImporting {
                guard let url = urls.first else {
                    parent.onImportCompleted(false, parent.localizationViewModel.localizedString("No file selected"))
                    return
                }
                importCSVFile(from: url)
            } else {
                parent.onImportCompleted(true, parent.localizationViewModel.localizedString("File exported successfully"))
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onImportCompleted(false, parent.localizationViewModel.localizedString("Operation cancelled"))
        }

        private func importCSVFile(from url: URL) {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                guard didStartAccessing else {
                    parent.onImportCompleted(false, parent.localizationViewModel.localizedString("Failed to access file: Permission denied"))
                    return
                }

                let content = try String(contentsOf: url, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                var importedCount = 0

                guard lines.count > 1 else {
                    parent.onImportCompleted(false, parent.localizationViewModel.localizedString("Empty or invalid CSV file"))
                    return
                }

                for line in lines.dropFirst() {
                    let components = line.components(separatedBy: ",")
                    guard components.count >= 6 else { continue }

                    let latitude = Double(components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))) ?? 0.0
                    let longitude = Double(components[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))) ?? 0.0
                    let timestampStr = components[3].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    let locationName = components[4].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    let category = components[5].trimmingCharacters(in: CharacterSet(charactersIn: "\""))

                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy h:mm a"
                    let timestamp = formatter.date(from: timestampStr) ?? Date()

                    let newLocation = parent.locationViewModel.saveLocation(
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: timestamp,
                        locationName: locationName,
                        category: category
                    )
                    if newLocation != nil {
                        importedCount += 1
                    }
                }

                parent.onImportCompleted(true, String(format: parent.localizationViewModel.localizedString("%d locations imported successfully"), importedCount))
            } catch {
                parent.onImportCompleted(false, "\(parent.localizationViewModel.localizedString("Error importing CSV file")): \(error.localizedDescription)")
            }
        }
    }
}

// MailComposerView để gửi email
struct MailComposerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = context.coordinator
        mailVC.setToRecipients(["support@locamark.com"])
        mailVC.setSubject("Feedback for Locamark")
        mailVC.setMessageBody("Hi Locamark Team,\n\nI have some feedback about the app:\n", isHTML: false)
        return mailVC
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView

        init(_ parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isPresented = false
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(isPresented: .constant(true))
            .environmentObject(LocationViewModel())
            .environmentObject(LocalizationViewModel())
    }
}
