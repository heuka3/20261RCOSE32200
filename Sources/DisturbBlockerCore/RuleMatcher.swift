import Foundation

public enum RuleMatcher {
    public static func matchingRule(for url: String, rules: [WebsiteRule]) -> WebsiteRule? {
        let normalizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedURL.isEmpty else { return nil }

        return rules.first { rule in
            guard rule.isEnabled else { return false }
            let needle = rule.contains.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !needle.isEmpty && normalizedURL.contains(needle)
        }
    }
}
