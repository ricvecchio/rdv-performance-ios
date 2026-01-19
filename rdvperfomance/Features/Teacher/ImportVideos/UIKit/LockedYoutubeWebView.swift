import SwiftUI
import WebKit

struct LockedYoutubeWebView: UIViewRepresentable {
    
    let videoId: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        config.allowsInlineMediaPlayback = false
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        
        let urlString = "https://m.youtube.com/watch?v=\(videoId)&playsinline=0"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            
            if let host = navigationAction.request.url?.host?.lowercased(),
               host.contains("youtube.com") || host.contains("youtu.be") {
                decisionHandler(.allow)
                return
            }
            
            decisionHandler(.cancel)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
                try {
                    document.documentElement.style.overflow = 'hidden';
                    document.body.style.overflow = 'hidden';
                    document.body.style.height = '100vh';
                    document.body.style.margin = '0';

                    var style = document.createElement('style');
                    style.innerHTML = `
                        header, ytm-pivot-bar, ytm-browse, ytm-item-section-renderer,
                        ytm-engagement-panel-section-list-renderer, ytm-comment-section-renderer,
                        ytm-slim-video-metadata-section-renderer,
                        ytm-video-with-context-renderer,
                        ytm-reel-shelf-renderer,
                        ytm-single-column-watch-next-results-renderer,
                        ytm-watch-next-secondary-results-renderer,
                        ytm-watch-next-feed,
                        #related, #secondary, #comments, #chips {
                            display: none !important;
                            visibility: hidden !important;
                            height: 0 !important;
                            overflow: hidden !important;
                        }
                        ytm-app, ytm-watch {
                            overflow: hidden !important;
                        }
                    `;
                    document.head.appendChild(style);

                    document.addEventListener('click', function(e) {
                        var a = e.target.closest('a');
                        if (a) { e.preventDefault(); e.stopPropagation(); }
                    }, true);
                } catch (e) {}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
