import AppKit

/// Lightweight, opt-in update checker. Polls GitHub's releases API once a
/// day, and if a newer release is published it asks `MenuController` to
/// surface an "Update available" entry at the top of the menu. No
/// background downloads, no auto-install — clicking the item opens the
/// release page in the browser.
final class UpdateChecker {
    static let endpoint = URL(string: "https://api.github.com/repos/HugoRS00/mac-mouse-improver/releases/latest")!

    private static let lastCheckKey = "MacMouseImprover.lastUpdateCheck"
    private static let skippedTagKey = "MacMouseImprover.skippedTag"
    private static let minInterval: TimeInterval = 24 * 60 * 60

    weak var menuController: MenuController?

    func checkIfDue() {
        let last = UserDefaults.standard.object(forKey: Self.lastCheckKey) as? Date ?? .distantPast
        guard Date().timeIntervalSince(last) > Self.minInterval else { return }
        checkNow()
    }

    func checkNow() {
        UserDefaults.standard.set(Date(), forKey: Self.lastCheckKey)

        var request = URLRequest(url: Self.endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("mac-mouse-improver", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard
                let self = self,
                let data = data,
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                let tag = json["tag_name"] as? String,
                let urlString = json["html_url"] as? String,
                let url = URL(string: urlString)
            else { return }

            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            guard Self.isNewer(latest, than: current) else { return }
            if UserDefaults.standard.string(forKey: Self.skippedTagKey) == tag { return }

            DispatchQueue.main.async {
                self.menuController?.showUpdateAvailable(version: latest, tag: tag, url: url)
            }
        }.resume()
    }

    static func markSkipped(tag: String) {
        UserDefaults.standard.set(tag, forKey: Self.skippedTagKey)
    }

    private static func isNewer(_ a: String, than b: String) -> Bool {
        let lhs = a.split(separator: ".").compactMap { Int($0) }
        let rhs = b.split(separator: ".").compactMap { Int($0) }
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l > r { return true }
            if l < r { return false }
        }
        return false
    }
}
