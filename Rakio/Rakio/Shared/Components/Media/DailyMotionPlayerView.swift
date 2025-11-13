import SwiftUI
import WebKit

struct DailymotionPlayerView: UIViewRepresentable {
    let videoID: String
    @Binding var isPlaying: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Always reload if videoID changes
        if context.coordinator.currentVideoID != videoID {
            let urlString = "https://www.dailymotion.com/embed/video/\(videoID)?autoplay=1&cc_lang=en"
            print("Loading Dailymotion URL: \(urlString)")
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                uiView.load(request)
                context.coordinator.currentVideoID = videoID
                context.coordinator.isReady = false
            }
        } else if context.coordinator.isReady {
            // Control playback
            let command = isPlaying ? "player.play();" : "player.pause();"
            uiView.evaluateJavaScript(command) { result, error in
                if let error = error {
                    print("⚠️ JS error: \(error.localizedDescription)")
                }
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var currentVideoID: String?
        var isReady: Bool = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            print("✅ Dailymotion player iframe ready for \(currentVideoID ?? "unknown")")
        }
    }
}
