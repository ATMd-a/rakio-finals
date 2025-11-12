import SwiftUI

struct WatchView: View {
    @StateObject private var viewModel = SeriesViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    private var enumeratedShows: [(offset: Int, element: Series)] {
        Array(viewModel.shows.enumerated())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Menu
            HStack {
                Text("Rakio")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
               
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // MARK: - Content Area
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading shows...")
                        .foregroundColor(.white)
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Error loading shows")
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
                        .background(Color(hex: "437C90"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    Spacer()
                }
            } else if viewModel.shows.isEmpty {
                VStack {
                    Spacer()
                    Text("No shows available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Check back later for new content")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            } else {
                // MARK: - Shows Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(enumeratedShows, id: \.offset) { index, show in
                                            // Navigation to SeriesDetailView
                                            // The SeriesDetailView now manages its own data loading
                                NavigationLink(destination: SeriesDetailView(show: show)) { // No need to pass viewModel
                                                SeriesCardView(series: show)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        
                                        if viewModel.shows.count % 2 != 0 {
                                            placeholderRect(size: CGSize(width: 163, height: 169))
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                }
                                .refreshable {
                                    await viewModel.refresh()
                                }
            }
        }
        .background(Color(hex: "14110F").ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            if viewModel.shows.isEmpty && !viewModel.isLoading {
                await viewModel.loadShows()
            }
        }
    }
    
    func placeholderRect(size: CGSize) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: size.width, height: size.height)
    }
}

