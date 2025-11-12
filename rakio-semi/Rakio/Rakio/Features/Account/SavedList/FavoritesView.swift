////
////  FavoritesView.swift
////  Rakio
////
////  Created by STUDENT on 10/14/25.
////
//
//
//import SwiftUI
//
//struct FavoritesView: View {
//    @StateObject private var viewModel = FavoritesViewModel()
//
//    var body: some View {
//        ZStack {
//            Color(hex: "14110F").ignoresSafeArea()
//
//            if viewModel.isLoading {
//                ProgressView("Loading favorites...")
//                    .foregroundColor(.white)
//            } else if let error = viewModel.errorMessage {
//                Text("⚠️ \(error)")
//                    .foregroundColor(.red)
//                    .padding()
//            } else if viewModel.favorites.isEmpty {
//                Text("You haven't saved any series yet.")
//                    .foregroundColor(.gray)
//                    .padding()
//            } else {
//                ScrollView {
//                    VStack(spacing: 16) {
//                        ForEach(viewModel.favorites) { series in
//                            NavigationLink(destination: SeriesDetailView(show: series)) {
//                                HStack(spacing: 15) {
//                                    Image(uiImage: UIImage(named: series.imageName) ?? UIImage())
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fill)
//                                        .frame(width: 100, height: 60)
//                                        .cornerRadius(6)
//                                        .clipped()
//
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text(series.title)
//                                            .font(.headline)
//                                            .foregroundColor(.white)
//                                        // Optional: Add more series info here
//                                    }
//
//                                    Spacer()
//                                }
//                                .padding()
//                                .background(Color.white.opacity(0.05))
//                                .cornerRadius(10)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("My Favorites")
//        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            await viewModel.fetchFavorites()
//        }
//    }
//}
