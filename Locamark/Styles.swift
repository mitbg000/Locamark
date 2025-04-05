//
//  Styles.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import SwiftUI

// Định nghĩa các kiểu font tái sử dụng
struct AppFont {
    static let largeTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let title = Font.system(size: 18, weight: .bold, design: .rounded)
    static let subtitle = Font.system(size: 16, weight: .medium, design: .rounded)
    static let body = Font.system(size: 18, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
    static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let smallButton = Font.system(size: 14, weight: .medium, design: .rounded)
}

// Định nghĩa các màu sắc tái sử dụng
struct AppColor {
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let buttonBackground = Color.blue
    static let buttonText = Color.white
    static let tagBackground = Color.gray.opacity(0.1)
    static let tagSelectedBackground = Color.blue.opacity(0.2)
    static let tagText = Color.gray
    static let tagSelectedText = Color.blue
    static let shadow = Color.black.opacity(0.05)
    static let background = Color(.systemBackground)
    static let error = Color.red
    static let accent = Color.orange // Dùng cho các yếu tố nổi bật như nút "Map"
}

// Định nghĩa các khoảng cách (padding, spacing) tái sử dụng
struct AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

// ViewModifier cho các nút chính (Primary Button)
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.button)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .background(AppColor.buttonBackground)
            .foregroundColor(AppColor.buttonText)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// ViewModifier cho các nút nhỏ (Small Button)
struct SmallButtonStyle: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(AppFont.smallButton)
            .padding(.vertical, 6)
            .padding(.horizontal, AppSpacing.medium)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// ViewModifier cho thẻ (Tag)
struct TagStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(AppFont.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? AppColor.tagSelectedBackground : AppColor.tagBackground)
            .foregroundColor(isSelected ? AppColor.tagSelectedText : AppColor.tagText)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// ViewModifier cho các mục vị trí (Location Item)
struct LocationItemStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColor.background)
                    .shadow(color: AppColor.shadow, radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
    }
}

// ViewModifier cho ô tìm kiếm (Search Bar)
struct SearchBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
    }
}

// ViewModifier cho container chính (Main Container)
struct MainContainerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColor.background)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ViewModifier cho tiêu đề điều hướng (Navigation Title)
struct NavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.title)
            .foregroundColor(AppColor.primaryText)
    }
}

// ViewModifier cho các phần tử trong Form
struct FormSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, AppSpacing.small)
    }
}

// Extension để áp dụng các modifier dễ dàng
extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
    
    func smallButtonStyle(backgroundColor: Color, foregroundColor: Color) -> some View {
        self.modifier(SmallButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
    
    func tagStyle(isSelected: Bool) -> some View {
        self.modifier(TagStyle(isSelected: isSelected))
    }
    
    func locationItemStyle() -> some View {
        self.modifier(LocationItemStyle())
    }
    
    func searchBarStyle() -> some View {
        self.modifier(SearchBarStyle())
    }
    
    func mainContainerStyle() -> some View {
        self.modifier(MainContainerStyle())
    }
    
    func navigationTitleStyle() -> some View {
        self.modifier(NavigationTitleStyle())
    }
    
    func formSectionStyle() -> some View {
        self.modifier(FormSectionStyle())
    }
}
