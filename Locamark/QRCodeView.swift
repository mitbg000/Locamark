//
//  QRCodeView.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI

struct QRCodeView: View {
    let location: LocationData
    @Binding var isPresented: QRCodeItem?
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @State private var qrCodeImage: UIImage? // Thêm biến trạng thái để lưu mã QR
    @State private var showSaveAlert: Bool = false
    @State private var saveError: String?
    private let photoSaver = PhotoSaver()

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.large) {
                // Tiêu đề vị trí
                Text(location.customName ?? location.locationName ?? localizationViewModel.localizedString("Unknown"))
                    .font(AppFont.title)
                    .foregroundColor(AppColor.primaryText)
                    .lineLimit(1)
                    .padding(.top, AppSpacing.large)

                // Mã QR
                if let image = qrCodeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 300 : 200,
                               height: UIDevice.current.userInterfaceIdiom == .pad ? 300 : 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColor.background)
                                .shadow(color: AppColor.shadow, radius: 4, x: 0, y: 2)
                        )
                } else {
                    Text(localizationViewModel.localizedString("Failed to generate QR code"))
                        .font(AppFont.subtitle)
                        .foregroundColor(AppColor.secondaryText)
                        .padding()
                }

                // Thông tin bổ sung
                VStack(spacing: AppSpacing.small) {
                    Text("\(localizationViewModel.localizedString("Latitude")): \(location.latitude), \(localizationViewModel.localizedString("Longitude")): \(location.longitude)")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryText)
                    Text(localizationViewModel.localizedString("Scan this QR code to share location"))
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.large)

                // Nút Save (Chỉ hiển thị khi có mã QR)
                if qrCodeImage != nil {
                    Button(action: { saveQRCodeToPhotos() }) {
                        Text(localizationViewModel.localizedString("Save QR Code"))
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, AppSpacing.large)
                }

                // Nút Close
                Button(action: { isPresented = nil }) {
                    Text(localizationViewModel.localizedString("Close"))
                        .font(AppFont.button)
                        .foregroundColor(AppColor.tagSelectedText)
                        .padding(.vertical, AppSpacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(AppColor.tagSelectedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, AppSpacing.large)
                .padding(.bottom, AppSpacing.large)

                Spacer()
            }
            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 600 : .infinity) // Giới hạn chiều rộng trên iPad
            .background(AppColor.background)
            .navigationTitle(localizationViewModel.localizedString("Share Location"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                qrCodeImage = locationViewModel.generateQRCode(from: location) // Tạo mã QR khi view xuất hiện
            }
            .alert(isPresented: $showSaveAlert) {
                if let errorMessage = saveError {
                    return Alert(
                        title: Text(localizationViewModel.localizedString("Error")),
                        message: Text(errorMessage),
                        dismissButton: .default(Text(localizationViewModel.localizedString("OK")))
                    )
                } else {
                    return Alert(
                        title: Text(localizationViewModel.localizedString("Success")),
                        message: Text(localizationViewModel.localizedString("QR code saved to Photos")),
                        dismissButton: .default(Text(localizationViewModel.localizedString("OK")))
                    )
                }
            }
        }
    }

    private func saveQRCodeToPhotos() {
        guard let image = qrCodeImage else { return } // Đảm bảo có hình ảnh để lưu
        photoSaver.saveImageToPhotos(image) { error in
            DispatchQueue.main.async {
                if let error = error {
                    saveError = error.localizedDescription
                } else {
                    saveError = nil
                }
                showSaveAlert = true
            }
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let location = LocationData(context: PersistenceController.preview.container.viewContext)
        location.id = UUID()
        location.latitude = 10.0
        location.longitude = 20.0
        location.timestamp = Date()
        location.locationName = "Test Location"
        location.category = "other"
        
        return QRCodeView(location: location, isPresented: .constant(QRCodeItem(location: location, isShowing: true)))
            .environmentObject(LocationViewModel())
            .environmentObject(LocalizationViewModel())
    }
}
