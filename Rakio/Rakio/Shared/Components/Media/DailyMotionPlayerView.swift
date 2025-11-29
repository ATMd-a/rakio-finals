import SwiftUI
import WebKit

struct DailymotionPlayerView: UIViewRepresentable {
    let videoID: String
    @Binding var isPlaying: Bool
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = false
        config.userContentController.add(context.coordinator, name: "playerEvent")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentVideoID != videoID {
            
            let urlString =
            """
            https://www.dailymotion.com/embed/video/\(videoID)?api=1&autoplay=0&mute=0&controls=1
            """
            
            print("Loading Dailymotion URL: \(urlString)")
            
            if let url = URL(string: urlString) {
                uiView.load(URLRequest(url: url))
                context.coordinator.currentVideoID = videoID
                context.coordinator.isPlayerLoaded = false
            }
            return
        }
        
        // Control
        if context.coordinator.isPlayerLoaded {
            let js = isPlaying ? "player.play();" : "player.pause();"
            uiView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("⚠️ JS error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var currentVideoID: String?
        var isPlayerLoaded = false
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Injecting Dailymotion API…")
            
            let js =
            """
            window.player = DM.player(document.querySelector("iframe"), {
                video: "\(currentVideoID ?? "")",
                width: "100%",
                height: "100%",
                params: { autoplay: 0, api: 1 }
            });

            // Forward events to Swift
            player.addEventListener("play", function() {
                window.webkit.messageHandlers.playerEvent.postMessage("play");
            });
            player.addEventListener("pause", function() {
                window.webkit.messageHandlers.playerEvent.postMessage("pause");
            });
            player.addEventListener("video_end", function() {
                window.webkit.messageHandlers.playerEvent.postMessage("ended");
            });
            """

            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("⚠️ Inject error: \(error.localizedDescription)")
                } else {
                    print("✅ Dailymotion API loaded.")
                    self.isPlayerLoaded = true
                }
            }
        }
        
        // Receive events from JS → Swift
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let event = message.body as? String else { return }
            print("📩 DM EVENT:", event)
        }
    }
}
