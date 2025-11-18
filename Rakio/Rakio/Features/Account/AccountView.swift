import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @Binding var selectedTab: ContentView.Tab
    @State private var showLogoutConfirmation = false

    init(selectedTab: Binding<ContentView.Tab>) {
        _selectedTab = selectedTab
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let user = viewModel.currentUser {
                NavigationLink(destination: EditAccountView().environmentObject(viewModel)) {
                    HStack(spacing: 16) {
                        Image(uiImage: viewModel.profileImage ?? UIImage(named: "MewerLogo_SBlackIcon")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 65, height: 65)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

                        Text(viewModel.currentUsername ?? viewModel.username(fromEmail: user.email ?? ""))
                            .foregroundColor(.white)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(height: 80)
                }

            } else {
                NavigationLink(destination: LoginView(selectedTab: .constant(.account)).navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 65, height: 65)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        Text("Login or Sign up")
                            .foregroundColor(.white)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(height: 80)
                }
            }

            // MARK: - History Section
            Text("History")
                .foregroundColor(.white)
                .font(.caption)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.currentUser == nil {
                        Text("Please log in to view your watch history")
                            .foregroundColor(.white)
                            .font(.body)
                    } else {
                        ForEach(viewModel.watchedHistory) { item in
                            NavigationLink(destination: SeriesDetailView(show: item.series)) {
                                ThumbnailView(watchedItem: item)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // MARK: - Content Section
            contentSection

            // MARK: - Logout Button
            logoutButton

            Spacer()
        }
        .padding(.top, 20)
        .background(Color.rakioBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadProfileImage()
            viewModel.fetchCurrentUsername()
        }


    }

    // MARK: - Sections
    private var contentSection: some View {
        VStack(spacing: 0) {
            if viewModel.currentUser == nil {
                NavigationLink(destination: LoginView(selectedTab: .constant(.account)).navigationBarBackButtonHidden(true)) {
                    row(title: "My List")
                }
                Divider().background(Color.white.opacity(0.4))
                NavigationLink(destination: LoginView(selectedTab: .constant(.account)).navigationBarBackButtonHidden(true)) {
                    row(title: "My Reminders")
                }
            } else {
                NavigationLink(destination: MyListView()) {
                    row(title: "My List")
                }
                Divider().background(Color.white.opacity(0.4))
                row(title: "My Reminders", isDisabled: true)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func row(title: String, isDisabled: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isDisabled ? .gray : .white)
                .font(.body)
            Spacer()
        }
        .padding()
    }

    private var logoutButton: some View {
        Group {
            if viewModel.currentUser != nil {
                Button(action: { showLogoutConfirmation = true }) {
                    Text("Logout")
                        .foregroundColor(.red)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .alert("Confirm Logout", isPresented: $showLogoutConfirmation) {
                    Button("Logout", role: .destructive) {
                        do {
                            try viewModel.logout()
                            selectedTab = .home
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        showLogoutConfirmation = false
                    }
                } message: {
                    Text("Are you sure you want to logout?")
                }
            }
        }
    }
}
