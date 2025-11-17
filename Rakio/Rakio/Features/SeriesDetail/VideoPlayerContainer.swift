//import SwiftUI
//
//struct VideoPlayerContainer: View {
//    @Binding var currentEpisode: Episode?
//    @Binding var isPlayerPlaying: Bool
//    @Binding var isUsingYouTube: Bool
//    @Binding var playerProgress: Double
//    
//    @StateObject private var orientation = OrientationManager()
//
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                if let episode = currentEpisode {
//                    Group {
//                        if isUsingYouTube {
//                            YouTubePlayerView(videos: episode.code, isPlaying: $isPlayerPlaying)
//                        } else {
//                            DailymotionPlayerView(videoID: episode.code.first ?? "",
//                                                  isPlaying: $isPlayerPlaying)
//                        }
//                    }
//                    .frame(
//                        width: orientation.isLandscape ? geo.size.height : geo.size.width,
//                        height: orientation.isLandscape ? geo.size.width : (geo.size.width * 9/16)
//                    )
//                    .position(
//                        x: orientation.isLandscape ? geo.size.height / 2 : geo.size.width / 2,
//                        y: orientation.isLandscape ? geo.size.width / 2 : geo.size.height / 2
//                    )
//                    .rotationEffect(orientation.isLandscape ? .degrees(90) : .zero)
//                    .clipped()
//                    
//                } else {
//                    Color.black.overlay(
//                        Text("No video selected")
//                            .foregroundColor(.white)
//                    )
//                }
//            }
//            .frame(width: geo.size.width, height: geo.size.height)
//        }
//        .frame(height: orientation.isLandscape
//               ? UIScreen.main.bounds.width
//               : UIScreen.main.bounds.width * 9/16)
//        .background(Color.black)
//        .cornerRadius(orientation.isLandscape ? 0 : 12)
//        .ignoresSafeArea(orientation.isLandscape ? .all : .container)
//    }
//}
