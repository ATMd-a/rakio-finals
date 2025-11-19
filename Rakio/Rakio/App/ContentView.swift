import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, watch, read, account
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .watch:
                        WatchView()
                    case .read:
                        ReadView()
                    case .account:
                        AccountView(selectedTab: $selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BottomNavBar(selectedTab: $selectedTab)
                    .frame(height: 68)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "0f0f0f"))
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(Color.rakioPrimary)
                            .frame(maxHeight: .infinity, alignment: .top),
                        alignment: .top
                    )
            }
        }
    }
}

