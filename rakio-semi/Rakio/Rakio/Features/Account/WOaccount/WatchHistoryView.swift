////
////  WatchHistoryView.swift
////  Rakio
////
////  Created by STUDENT on 10/28/25.
////
//
//
//import SwiftUI
//
//struct WatchHistoryView: View {
//    @ObservedObject var viewModel: WatchHistoryViewModel
//
//    var body: some View {
//        ScrollView {
//            LazyVStack(spacing: 12) {
//                ForEach(viewModel.recentWatchedSeries) { watchedItem in
//                    NavigationLink(destination: SeriesDetailView(show: watchedItem.series)) {
//                        HStack(spacing: 12) {
//                            Image(uiImage: UIImage(named: watchedItem.series.imageName) ?? UIImage())
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 100, height: 60)
//                                .cornerRadius(8)
//                                .clipped()
//                            
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(watchedItem.series.title)
//                                    .foregroundColor(.white)
//                                    .font(.headline)
//                                Text(watchedItem.episode?.title ?? "Continue Watching")
//                                    .foregroundColor(.gray)
//                                    .font(.caption)
//                            }
//                            Spacer()
//                            Text(watchedItem.lastWatchedAt, style: .time)
//                                .foregroundColor(.gray)
//                                .font(.caption)
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
//            .padding(.top)
//        }
//        .background(Color(hex: "14110F").ignoresSafeArea())
//        .navigationTitle("Watch History")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
