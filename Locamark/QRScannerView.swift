//
//  QRScannerView.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI
import PhotosUI

struct QRScannerView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @StateObject private var scannerViewModel = QRScannerViewModel()
    @Binding var isPresented: Bool
    @State private var showAlert = false
    @State private var alertMessage: String?
    @State private var showImagePicker = false

    var body: some View {
        ZStack {
            // Hiển thị camera
            Color.black.edgesIgnoringSafeArea(.all)
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ViewSizeKey.self, value: geometry.size)
                    }
                )
                .onPreferenceChange(ViewSizeKey.self) { size in
                    if !scannerViewModel.isScanning && size.width > 0 && size.height > 0 {
                        scannerViewModel.startScanning(in: UIApplication.shared.windows.first?.rootViewController?.view ?? UIView()) { scannedData in
                            if let data = scannedData {
                                processScannedData(data)
                            }
                            // Không hiển thị thông báo khi không tìm thấy mã QR
                        }
                    }
                }

            // Hiển thị khung quét
            VStack {
                Spacer()
                Color.green
                    .frame(width: 200, height: 200)
                    .overlay(
                        Text(localizationViewModel.localizedString("Scan QR Code"))
                            .font(AppFont.subtitle)
                            .foregroundColor(AppColor.buttonText)
                    )
                Spacer()
            }

            // Nút đóng và nút quét từ ảnh
            VStack {
                HStack {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                    Button(action: {
                        scannerViewModel.stopScanning()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(localizationViewModel.localizedString("Scan Result")),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text(localizationViewModel.localizedString("OK"))) {
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                if let selectedImage = image {
                    scannerViewModel.scanQRFromImage(selectedImage) { scannedData in
                        if let data = scannedData {
                            processScannedData(data)
                        } else {
                            alertMessage = localizationViewModel.localizedString("No QR code found in image")
                            showAlert = true
                        }
                        isPresented = false
                    }
                }
            }
        }
        .onDisappear {
            scannerViewModel.stopScanning()
        }
    }

    // Xử lý dữ liệu quét từ mã QR
    private func processScannedData(_ data: String) {
        let lines = data.components(separatedBy: .newlines)
        var latitude: Double?
        var longitude: Double?
        var locationName: String?
        var category: String?

        for line in lines {
            if line.hasPrefix("Latitude: ") {
                latitude = Double(line.replacingOccurrences(of: "Latitude: ", with: ""))
            } else if line.hasPrefix("Longitude: ") {
                longitude = Double(line.replacingOccurrences(of: "Longitude: ", with: ""))
            } else if line.hasPrefix("Location: ") {
                locationName = line.replacingOccurrences(of: "Location: ", with: "")
            } else if line.hasPrefix("Category: ") {
                category = line.replacingOccurrences(of: "Category: ", with: "").lowercased()
            }
        }

        if let lat = latitude, let lon = longitude, let name = locationName {
            let newLocation = locationViewModel.saveLocation(
                latitude: lat,
                longitude: lon,
                timestamp: Date(),
                locationName: name,
                category: category ?? "other"
            )
            DispatchQueue.main.async {
                locationViewModel.locations.insert(newLocation, at: 0)
                alertMessage = localizationViewModel.localizedString("Location marked successfully")
                showAlert = true
            }
        } else {
            alertMessage = localizationViewModel.localizedString("Invalid QR code data")
            showAlert = true
        }
    }
}

// View để chọn ảnh từ thư viện
struct ImagePicker: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else {
                self.parent.completion(nil)
                return
            }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.completion(image)
                    }
                } else {
                    self.parent.completion(nil)
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

// Key để lấy kích thước view
struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct QRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerView(isPresented: .constant(true))
            .environmentObject(LocationViewModel())
            .environmentObject(LocalizationViewModel())
    }
}
