import SwiftUI

struct ContentView: View {
    let document: MarkdownDocument
    @State private var findQuery: String = ""
    @State private var showFind: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            WebView(markdown: document.text)
                .frame(minWidth: 640, minHeight: 480)
                .background(Color(nsColor: .textBackgroundColor))

            if showFind {
                FindBar(
                    query: $findQuery,
                    onClose: {
                        showFind = false
                        findQuery = ""
                    },
                    onSubmit: { forward in
                        post(.findRequest, userInfo: ["query": findQuery, "forward": forward])
                    }
                )
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showFind)
        .onReceive(NotificationCenter.default.publisher(for: .toggleFindBar)) { _ in
            if showFind {
                showFind = false
                findQuery = ""
            } else {
                showFind = true
            }
        }
    }

    private func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
}
