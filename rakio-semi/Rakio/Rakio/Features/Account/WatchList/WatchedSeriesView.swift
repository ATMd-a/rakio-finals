////
////  WatchedSeriesView.swift
////  Rakio
////
////  Created by STUDENT on 10/15/25.
////
//
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//// Assuming 'Series' and 'SeriesDetailView' are defined and accessible
//
//struct WatchedListView: View {
//    // 💡 FIX: Initialize the ViewModel class, not the View struct
//    @StateObject private var viewModel = WatchedListViewModel()
//
//    var body: some View {
//        ZStack {
//            Color(hex: "14110F").ignoresSafeArea()
//
//            if viewModel.isLoading {
//                ProgressView("Loading Watch History...")
//                    .foregroundColor(.white)
//            } else if let error = viewModel.errorMessage {
//                Text(error)
//                    .foregroundColor(.red)
//                    .padding()
//            } else if viewModel.watchedSeries.isEmpty {
//                VStack { // Added VStack for better empty state display
//                    Text("Your watch history is empty.")
//                        .foregroundColor(.gray)
//                        .padding(.bottom, 2)
//                    Text("Start watching a series to see it here!")
//                        .foregroundColor(.gray.opacity(0.8))
//                        .font(.caption)
//                }
//            } else {
//                ScrollView {
//                    VStack(spacing: 16) {
//                        ForEach(viewModel.watchedSeries) { series in
//                            // Reusing the list item UI from MyListView
//                            NavigationLink(destination: SeriesDetailView(show: series)) {
//                                HStack(spacing: 12) {
//                                    Image(uiImage: UIImage(named: series.imageName) ?? UIImage())
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fill)
//                                        .frame(width: 100, height: 60)
//                                        .cornerRadius(8)
//                                        .clipped()
//
//                                    VStack(alignment: .leading) {
//                                        Text(series.title)
//                                            .font(.headline)
//                                            .foregroundColor(.white)
//                                            
//                                        // Display a brief history status
//                                        // NOTE: This date is likely wrong. The Series model might not
//                                        // have the last watched date. You would need to look up
//                                        // the latest date from the user's watchHistory map in the ViewModel.
//                                        Text("Last watched: \(formatDate(series.dateReleased.dateValue()))")
//                                            .font(.subheadline)
//                                            .foregroundColor(.gray)
//                                    }
//
//                                    Spacer()
//                                }
//                                .padding(.horizontal)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .padding(.top)
//                }
//            }
//        }
//        .navigationTitle("Continue Watching")
//        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            // Load the watched series when the view appears
//            await viewModel.fetchWatchedSeries()
//        }
//    }
//    
//    // Helper function to format the date
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .none
//        return formatter.string(from: date)
//    }
//}
