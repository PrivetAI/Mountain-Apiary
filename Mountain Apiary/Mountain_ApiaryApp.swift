import SwiftUI

@main
struct Mountain_ApiaryApp: App {
    @State private var mountainApiaryLinkReady: Bool? = nil
    private let mountainApiarySourceLink = "https://mountainapiary.org/click.php"
    private let mountainApiaryCheckDomain = "privacypolicies.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = mountainApiaryLinkReady {
                    if ready {
                        MountainApiaryWebPanel(urlString: mountainApiarySourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .preferredColorScheme(.light)
                    }
                } else {
                    MountainApiaryLoadingScreen()
                        .onAppear { checkMountainApiaryLink() }
                }
            }
        }
    }

    private func checkMountainApiaryLink() {
        guard let url = URL(string: mountainApiarySourceLink) else {
            mountainApiaryLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = MountainApiaryRedirectTracker(checkDomain: mountainApiaryCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    mountainApiaryLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.mountainApiaryCheckDomain) {
                    mountainApiaryLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.mountainApiaryCheckDomain) {
                    mountainApiaryLinkReady = false; return
                }
                if error != nil {
                    mountainApiaryLinkReady = false; return
                }
                mountainApiaryLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if mountainApiaryLinkReady == nil { mountainApiaryLinkReady = false }
        }
    }
}

class MountainApiaryRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
