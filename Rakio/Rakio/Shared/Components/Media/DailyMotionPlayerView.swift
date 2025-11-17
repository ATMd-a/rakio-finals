import SwiftUI
import WebKit

struct DailymotionPlayerView: UIViewRepresentable {
    let videoID: String
    @Binding var isPlaying: Bool
    
    // MARK: - Coordinator Setup
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    // MARK: - makeUIView (Initialize WKWebView)
    func makeUIView(context: Context) -> WKWebView {
        // 1. Define the Configuration
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Allow playback without user action, but we will control it with JS later
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Disable Picture-in-Picture
        config.allowsPictureInPictureMediaPlayback = false
        
        // 2. Declare and Initialize the WKWebView ONCE with the configuration
        let webView = WKWebView(frame: .zero, configuration: config) // <-- Use this line!
        
        // Prevent scrolling (optional, for cleaner UX)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // Set the Coordinator as the delegate
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    // MARK: - updateUIView (Load/Control Logic)
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentVideoID != videoID {
            
            // 1. Load: Set autoplay=0 and enable JS API interaction
            let urlString = "https://www.dailymotion.com/embed/video/\(videoID)?autoplay=0&api=1&cc_lang=en&ui-start-screen-info=false&mute=0"
            print("Loading Dailymotion URL: \(urlString)")
            
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                uiView.load(request)
                context.coordinator.currentVideoID = videoID
                context.coordinator.isReady = false
                context.coordinator.hasSentReadyCommand = false // Reset control flag
            }
        } else if context.coordinator.isReady {
            
            // 2. Control: Use Dailymotion API commands for play/pause
            let command: String
            if isPlaying {
                // Use the API command for playing
                command = "player.api('play');"
            } else {
                // Use the API command for pausing
                command = "player.api('pause');"
            }
            
            // CRITICAL: Only send the command once the view's state changes
            if context.coordinator.hasSentReadyCommand != isPlaying {
                 uiView.evaluateJavaScript(command) { result, error in
                    if let error = error {
                        print("⚠️ JS error: \(error.localizedDescription)")
                    } else {
                        // Update the flag to prevent repeated calls
                        context.coordinator.hasSentReadyCommand = self.isPlaying
                    }
                 }
            }
        }
    }
    
    // MARK: - Coordinator Class
    class Coordinator: NSObject, WKNavigationDelegate {
        var currentVideoID: String?
        var isReady: Bool = false
        // New flag to track the last sent play/pause state
        var hasSentReadyCommand: Bool = false
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Wait for a small delay to ensure the Dailymotion JS player object is initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isReady = true
                print("✅ Dailymotion player iframe ready for \(self.currentVideoID ?? "unknown")")
            }
        }
    }
}
