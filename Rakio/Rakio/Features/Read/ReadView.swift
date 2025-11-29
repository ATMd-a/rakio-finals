import SwiftUI

struct ReadView: View {
    @StateObject private var viewModel = NovelViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rakio")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
               
            }
            .padding(.horizontal)
            .padding(.top, 20)

            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading novels...")
                        .foregroundColor(.white)
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Error loading novels")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.rakioPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    Spacer()
                }
            } else if viewModel.novels.isEmpty {
                VStack {
                    Spacer()
                    Text("No novels available")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Check back later for new content")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            } else {
                // Novels List
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.novels) { novel in
                            NavigationLink(destination: NovelDetailView(novelId: novel.id!)) {
                                NovelRowView(novel: novel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                    .padding(.leading, -20)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .background(Color.rakioBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            if viewModel.novels.isEmpty && !viewModel.isLoading {
                await viewModel.loadNovels()
            }
        }
    }
}
