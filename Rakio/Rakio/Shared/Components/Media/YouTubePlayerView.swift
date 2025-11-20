import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    @Binding var isPlaying: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load once
        if !context.coordinator.loaded {
            loadVideo(into: uiView)
            context.coordinator.loaded = true
        } else {
            // Dynamic play/pause
            let js = isPlaying ? "player.playVideo();" : "player.pauseVideo();"
            uiView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func loadVideo(into webView: WKWebView) {
        let bundleID = Bundle.main.bundleIdentifier ?? "invalid.bundle"
        let referer = "https://\(bundleID)"

        // Autoplay + muted + captions
        let urlString = """
        https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1&mute=1&controls=1&enablejsapi=1&cc_load_policy=1&cc_lang_pref=en
        """

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue(referer, forHTTPHeaderField: "Referer")

        webView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubePlayerView
        var loaded = false

        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ YouTube embed loaded successfully")

            // Optional: Unmute automatically after a short delay
            let unmuteJS = """
            setTimeout(function() {
                if (window.player && player.unMute) {
                    player.unMute();
                }
            }, 500);
            """
            webView.evaluateJavaScript(unmuteJS, completionHandler: nil)
        }
    }
}
