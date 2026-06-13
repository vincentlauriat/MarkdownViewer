#if os(macOS)
import SwiftUI
import AppKit

private let readmeRawURL = URL(string: "https://raw.githubusercontent.com/vincentlauriat/MarkdownViewer/main/README.md")!
private let readmePageURL = URL(string: "https://github.com/vincentlauriat/MarkdownViewer#readme")!
private let releasesAPIURL = URL(string: "https://api.github.com/repos/vincentlauriat/MarkdownViewer/releases/latest")!
private let releasesPageURL = URL(string: "https://github.com/vincentlauriat/MarkdownViewer/releases")!
private let repoPageURL = URL(string: "https://github.com/vincentlauriat/MarkdownViewer")!

private enum LoadPhase {
    case loading
    case loaded
    case failed(String)
}

/// Internal Help window — fetches `README.md` from GitHub raw and renders it in
/// the existing `WebView` (same Markdown pipeline as document rendering).
struct HelpWindowView: View {
    @State private var markdown = ""
    @State private var phase: LoadPhase = .loading

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            FooterBar(title: "View README on GitHub", url: readmePageURL)
        }
        .frame(minWidth: 640, minHeight: 520)
        .task { await load() }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch phase {
        case .loading:
            ProgressView("Loading Help…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 8) {
                Text("Couldn't load Help.").font(.headline)
                Text(message).foregroundStyle(.secondary).font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            WebView(markdown: markdown)
        }
    }

    private func load() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: readmeRawURL)
            markdown = String(data: data, encoding: .utf8) ?? ""
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

/// Internal What's New window — fetches the GitHub Releases for this repo and
/// stitches their markdown bodies into a single document, rendered by `WebView`.
struct WhatsNewWindowView: View {
    @State private var markdown = ""
    @State private var phase: LoadPhase = .loading

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            FooterBar(title: "View all releases on GitHub", url: releasesPageURL)
        }
        .frame(minWidth: 640, minHeight: 520)
        .task { await load() }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch phase {
        case .loading:
            ProgressView("Loading release notes…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 8) {
                Text("Couldn't load release notes.").font(.headline)
                Text(message).foregroundStyle(.secondary).font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            WebView(markdown: markdown)
        }
    }

    private func load() async {
        struct Release: Decodable {
            let tagName: String
            let name: String?
            let publishedAt: String
            let body: String?

            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case name
                case publishedAt = "published_at"
                case body
            }
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: releasesAPIURL)
            let release = try JSONDecoder().decode(Release.self, from: data)
            let title = release.name ?? release.tagName
            let date = String(release.publishedAt.prefix(10))
            let body = (release.body?.isEmpty == false) ? release.body! : "_(no notes for this release)_"
            markdown = "# \(title)\n\n_\(date)_\n\n\(body)"
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

/// Custom About window — replaces the SwiftUI default About panel so we can
/// embed a "View on GitHub" button alongside name / version / copyright.
struct AboutWindowView: View {
    var body: some View {
        VStack(spacing: 14) {
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            }
            Text("MarkdownViewer")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Version \(version) (\(build))")
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text("A native macOS app to open Markdown files instantly from Finder.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.callout)
                .frame(maxWidth: 280)
            Button("View on GitHub") { NSWorkspace.shared.open(repoPageURL) }
                .padding(.top, 4)
            Text("MIT License — © 2026 Vincent Lauriat")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(width: 380)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

/// Bottom action bar with a single "Open on GitHub" link button.
private struct FooterBar: View {
    let title: String
    let url: URL

    var body: some View {
        HStack {
            Spacer()
            Button(title) { NSWorkspace.shared.open(url) }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .background(.regularMaterial)
    }
}
#endif
