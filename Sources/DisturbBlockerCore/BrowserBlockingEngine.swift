import Foundation

public enum SupportedBrowser: String, CaseIterable, Sendable {
    case safari = "Safari"
    case chrome = "Google Chrome"

    public var displayName: String {
        rawValue
    }

    var urlReadScript: String {
        switch self {
        case .safari:
            return """
            tell application "Safari"
                if it is not running then return ""
                if (count of windows) is 0 then return ""
                return URL of current tab of front window
            end tell
            """
        case .chrome:
            return """
            tell application "Google Chrome"
                if it is not running then return ""
                if (count of windows) is 0 then return ""
                return URL of active tab of front window
            end tell
            """
        }
    }

    func navigateScript(to url: String) -> String {
        let escaped = url.replacingOccurrences(of: "\"", with: "\\\"")
        switch self {
        case .safari:
            return """
            tell application "Safari"
                if it is not running then return
                if (count of windows) is 0 then return
                set URL of current tab of front window to "\(escaped)"
            end tell
            """
        case .chrome:
            return """
            tell application "Google Chrome"
                if it is not running then return
                if (count of windows) is 0 then return
                set URL of active tab of front window to "\(escaped)"
            end tell
            """
        }
    }
}

public final class BrowserBlockingEngine {
    public var isDryRun: Bool
    private let warningPageURL: String

    public init(isDryRun: Bool = false, warningPageURL: String = "about:blank") {
        self.isDryRun = isDryRun
        self.warningPageURL = warningPageURL
    }

    public func enforce(mode: BlockMode) -> [BlockEvent] {
        guard !mode.websiteRules.isEmpty else { return [] }

        return SupportedBrowser.allCases.compactMap { browser in
            do {
                let url = try currentURL(in: browser)
                guard let url, let rule = RuleMatcher.matchingRule(for: url, rules: mode.websiteRules) else {
                    return nil
                }

                if isDryRun {
                    return BlockEvent(
                        kind: .website,
                        target: browser.displayName,
                        message: "Dry run: matched '\(rule.contains)' in \(url).",
                        succeeded: true
                    )
                }

                try navigate(browser, to: warningPage(for: mode, rule: rule))
                return BlockEvent(
                    kind: .website,
                    target: browser.displayName,
                    message: "Redirected blocked URL matching '\(rule.contains)'.",
                    succeeded: true
                )
            } catch {
                return BlockEvent(
                    kind: .website,
                    target: browser.displayName,
                    message: error.localizedDescription,
                    succeeded: false
                )
            }
        }
    }

    private func currentURL(in browser: SupportedBrowser) throws -> String? {
        let output = try runAppleScript(browser.urlReadScript)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return output.isEmpty ? nil : output
    }

    private func navigate(_ browser: SupportedBrowser, to url: String) throws {
        _ = try runAppleScript(browser.navigateScript(to: url))
    }

    private func warningPage(for mode: BlockMode, rule: WebsiteRule) -> String {
        guard warningPageURL == "about:blank" else {
            return warningPageURL
        }

        let title = "Blocked by Disturb Blocker"
        let body = "\(mode.name) mode blocked a page matching \(rule.contains)."
        let html = """
        <html><head><title>\(title)</title></head><body style="font-family:-apple-system;padding:40px"><h1>\(title)</h1><p>\(body)</p></body></html>
        """
        return "data:text/html,\(html.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title)"
    }

    private func runAppleScript(_ source: String) throws -> String {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw BrowserScriptError.invalidScript
        }

        let descriptor = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "AppleScript failed."
            throw BrowserScriptError.executionFailed(message)
        }
        return descriptor.stringValue ?? ""
    }
}

public enum BrowserScriptError: LocalizedError {
    case invalidScript
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidScript:
            return "Could not create AppleScript."
        case .executionFailed(let message):
            return message
        }
    }
}
