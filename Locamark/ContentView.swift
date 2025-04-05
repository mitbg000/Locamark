//
//  ContentView.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let location: LocationData
    let isShowing: Bool
}

struct QRCodeItem: Identifiable {
    let id = UUID()
    let location: LocationData
    let isShowing: Bool
}

struct ContentView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @State private var selectedLocation: LocationData?
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var isSettingSheetPresented = false
    @State private var refreshId = UUID()
    @State private var showDeleteAlert: AlertItem?
    @State private var showQRCode: QRCodeItem?
    @State private var showQRScanner = false

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 768 { // iPad
                NavigationView {
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            SearchBar(text: $searchText)
                                .padding()
                            categoryFilterView
                            timelineView
                                .frame(maxHeight: .infinity)
                        }
                        .background(AppColor.background)

                        if let selected = selectedLocation {
                            LocationDetailView(location: selected)
                                .frame(maxWidth: .infinity)
                        } else {
                            markLocationView
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .navigationTitle(localizationViewModel.localizedString("Locations"))
                    .toolbar { toolbarItems }
                }
            } else { // iPhone
                NavigationView {
                    VStack(spacing: 0) {
                        if let error = locationViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                        SearchBar(text: $searchText)
                            .padding(.horizontal, AppSpacing.large)
                            .padding(.vertical, AppSpacing.small)
                        categoryFilterView
                        timelineView
                        markLocationView
                    }
                    .navigationTitle(localizationViewModel.localizedString("Locations"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbarItems }
                    .onChange(of: searchText) { newValue in // Thêm dòng này
                        locationViewModel.fetchLocations(with: newValue, category: selectedCategory)
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingSheetPresented) {
            SettingView(isPresented: $isSettingSheetPresented)
                .environmentObject(locationViewModel)
                .environmentObject(localizationViewModel)
        }
        .sheet(item: $selectedLocation) { location in
            EditLocationSheet(location: location)
                .environmentObject(locationViewModel)
                .environmentObject(localizationViewModel)
        }
        .alert(item: $showDeleteAlert) { item in
            Alert(
                title: Text(localizationViewModel.localizedString("Confirm Delete")),
                message: Text(localizationViewModel.localizedString("Are you sure you want to delete this location?")),
                primaryButton: .destructive(Text(localizationViewModel.localizedString("Delete"))) {
                    locationViewModel.deleteLocation(item.location) {
                        DispatchQueue.main.async {
                            locationViewModel.fetchLocations()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $showQRCode) { item in
            QRCodeView(location: item.location, isPresented: $showQRCode)
                .environmentObject(locationViewModel)
                .environmentObject(localizationViewModel)
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView(isPresented: $showQRScanner)
                .environmentObject(locationViewModel)
                .environmentObject(localizationViewModel)
        }
        .preferredColorScheme(localizationViewModel.isDarkMode ? .dark : .light)
        .environment(\.locale, Locale(identifier: localizationViewModel.currentLanguage))
        .id(refreshId)
        .onChange(of: localizationViewModel.currentLanguage) { _ in
            refreshId = UUID() // Làm mới giao diện khi ngôn ngữ thay đổi
        }
        .onAppear {
            locationViewModel.fetchInitialData()
        }
    }

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                Button(action: {
                    selectedCategory = nil
                    locationViewModel.fetchLocations(with: searchText, category: nil)
                }) {
                    Text(localizationViewModel.localizedString("All"))
                        .tagStyle(isSelected: selectedCategory == nil)
                }
                ForEach(LocationCategory.allCases) { category in
                    Button(action: {
                        selectedCategory = category.rawValue
                        locationViewModel.fetchLocations(with: searchText, category: category.rawValue)
                    }) {
                        Text(category.localizedName(using: localizationViewModel))
                            .tagStyle(isSelected: selectedCategory == category.rawValue)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.large)
        }
        .frame(height: 30)
    }

    private var timelineView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                if locationViewModel.locations.isEmpty {
                    Text(localizationViewModel.localizedString("No results found"))
                        .font(AppFont.subtitle)
                        .foregroundColor(AppColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(locationViewModel.locations.sorted(by: { $0.timestamp ?? Date() > $1.timestamp ?? Date() })) { location in
                        TimelineItemView(
                            location: location,
                            selectedLocation: $selectedLocation,
                            showQRCode: $showQRCode,
                            onDelete: { showDeleteAlert = AlertItem(location: location, isShowing: true) },
                            onShowQR: { showQRCode = QRCodeItem(location: location, isShowing: true) },
                            onEdit: { selectedLocation = location }
                        )
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(AppColor.background)
    }

    private var markLocationView: some View {
        Button(action: { locationViewModel.markCurrentLocation() }) {
            Text(localizationViewModel.localizedString("Mark Location"))
                .primaryButtonStyle()
        }
        .padding()
        .background(AppColor.background.overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .top))
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showQRScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(AppColor.primaryText)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(localizationViewModel.localizedString("Locations"))
                    .font(AppFont.title)
                    .foregroundColor(AppColor.primaryText)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isSettingSheetPresented = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(AppColor.primaryText)
                }
            }
        }
    }
}

struct LocationDetailView: View {
    let location: LocationData
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(location.customName ?? location.locationName ?? localizationViewModel.localizedString("Unknown"))
                .font(AppFont.title)
                .foregroundColor(AppColor.primaryText)
            Text(location.timestamp?.formatted(date: .numeric, time: .shortened) ?? "")
                .font(AppFont.subtitle)
                .foregroundColor(AppColor.secondaryText)
            Text("Latitude: \(location.latitude), Longitude: \(location.longitude)")
                .font(AppFont.body)
            Text("#\(location.category?.capitalized ?? localizationViewModel.localizedString("Other"))")
                .tagStyle(isSelected: location.category != "other")
            Spacer()
            HStack(spacing: AppSpacing.large) {
                Button(action: { locationViewModel.shareLocation(location) }) {
                    Image(systemName: "square.and.arrow.up")
                        .smallButtonStyle(backgroundColor: AppColor.tagSelectedBackground, foregroundColor: AppColor.tagSelectedText)
                }
                Button(action: { locationViewModel.openInMaps(location) }) {
                    Image(systemName: "map")
                        .smallButtonStyle(backgroundColor: Color.orange.opacity(0.1), foregroundColor: .orange)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(AppColor.background)
    }
}

struct TimelineItemView: View {
    let location: LocationData
    @Binding var selectedLocation: LocationData?
    @Binding var showQRCode: QRCodeItem?
    let onDelete: () -> Void
    let onShowQR: () -> Void
    let onEdit: () -> Void
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var localizationViewModel: LocalizationViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            // Đường timeline
            VStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(AppColor.primaryText)
                Rectangle()
                    .frame(width: 2)
                    .foregroundColor(AppColor.secondaryText.opacity(0.5))
                    .padding(.top, AppSpacing.small)
            }
            .frame(width: 20)

            // Nội dung vị trí
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                // Trên cùng: Custom name (nếu có)
                if let customName = location.customName, !customName.isEmpty {
                    Text(customName)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.primaryText)
                        .lineLimit(1)
                }

                // Bên dưới: Tên vị trí thực tế
                Text(location.locationName ?? localizationViewModel.localizedString("Unknown"))
                    .font(AppFont.body)
                    .foregroundColor(AppColor.primaryText)
                    .lineLimit(1)

                // Bên dưới nữa: Ngày giờ
                Text(location.timestamp?.formatted(date: .numeric, time: .shortened) ?? "")
                    .font(AppFont.subtitle)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(1)

                // Cuối cùng: Hashtag và nút
                HStack {
                    // Hashtag bên trái
                    if let category = location.category, !category.isEmpty, category != "other" {
                        Text("#\(category.capitalized)")
                            .tagStyle(isSelected: true)
                    } else {
                        Text("#\(localizationViewModel.localizedString("Other"))")
                            .tagStyle(isSelected: false)
                    }

                    // Nút icon bên phải
                    HStack(spacing: AppSpacing.medium) {
                        Button(action: { locationViewModel.shareLocation(location) }) {
                            Image(systemName: "square.and.arrow.up")
                                .smallButtonStyle(backgroundColor: AppColor.tagSelectedBackground, foregroundColor: AppColor.tagSelectedText)
                        }
                        Button(action: { locationViewModel.openInMaps(location) }) {
                            Image(systemName: "map")
                                .smallButtonStyle(backgroundColor: Color.orange.opacity(0.1), foregroundColor: .orange)
                        }
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .smallButtonStyle(backgroundColor: AppColor.tagBackground, foregroundColor: AppColor.tagText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColor.background)
                .shadow(color: AppColor.shadow, radius: 4, x: 0, y: 2)
        )
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        withAnimation {
                            dragOffset = value.translation.width
                            isDragging = true
                        }
                    }
                }
                .onEnded { value in
                    withAnimation {
                        let translation = value.translation.width
                        if abs(translation) > abs(value.translation.height) {
                            if translation > 100 {
                                onDelete()
                                dragOffset = 0
                            } else if translation < -100 {
                                onShowQR()
                                dragOffset = 0
                            } else {
                                dragOffset = 0
                            }
                        } else {
                            dragOffset = 0
                        }
                        isDragging = false
                    }
                }
        )
        .contextMenu {
            Button(action: { onDelete() }) {
                Label(localizationViewModel.localizedString("Delete"), systemImage: "trash")
            }
            Button(action: { onShowQR() }) {
                Label(localizationViewModel.localizedString("Show QR Code"), systemImage: "qrcode")
            }
        }
        .onTapGesture {
            selectedLocation = location
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationViewModel())
            .environmentObject(LocalizationViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
