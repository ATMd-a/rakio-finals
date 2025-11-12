import SwiftUI

struct MyListView: View {
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        ZStack {
            Color(hex: "14110F").ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .foregroundColor(.white)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.favorites.isEmpty {
                Text("No series in your list yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.favorites) { series in
                            NavigationLink(destination: SeriesDetailView(show: series)) {
                                HStack(spacing: 12) {
                                    Image(uiImage: UIImage(named: series.imageName) ?? UIImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 60)
                                        .cornerRadius(8)
                                        .clipped()

                                    VStack(alignment: .leading) {
                                        Text(series.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(series.genre.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("My List")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchFavorites()
        }
    }
}
