import Foundation

struct RecentSearchItem: Codable, Identifiable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date

    init(query: String) {
        self.id = UUID()
        self.query = query
        self.timestamp = Date()
    }
}

final class RecentSearchManager {
    static let shared = RecentSearchManager()

    private init() {}

    private let key = "recentSearches"
    private let maxCount = 10

    func getRecentSearches() -> [RecentSearchItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([RecentSearchItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var searches = getRecentSearches()
        searches.removeAll { $0.query.lowercased() == trimmed.lowercased() }
        searches.insert(RecentSearchItem(query: trimmed), at: 0)

        if searches.count > maxCount {
            searches = Array(searches.prefix(maxCount))
        }

        if let data = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func removeSearch(_ id: UUID) {
        var searches = getRecentSearches()
        searches.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
