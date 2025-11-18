//
//  BottomNavBar.swift
//  Test3
//
//  Created by STUDENT on 8/29/25.
//


import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: ContentView.Tab

    let iconSize: CGFloat = 24
    let labelFontSize: CGFloat = 10
    let defaultColor = Color(hex: "EEEBD3")
    let selectedColor = Color.rakioPrimary

    var body: some View {
        HStack(spacing: 0) {
            navItem(iconName: "house.fill", label: "Home", tab: .home)
            navItem(iconName: "tv.fill", label: "Watch", tab: .watch)
            navItem(iconName: "book.fill", label: "Read", tab: .read)
            Spacer()
            navItem(iconName: "person.fill", label: "My account", tab: .account)
        }
        .padding(.horizontal, 5)
    }

    func navItem(iconName: String, label: String, tab: ContentView.Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: iconSize)
                    .foregroundColor(isSelected ? selectedColor : defaultColor)
                Text(label)
                    .font(.system(size: labelFontSize))
                    .foregroundColor(isSelected ? selectedColor : defaultColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
