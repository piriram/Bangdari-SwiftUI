import Foundation

struct SearchState {
    var searchQuery: String = ""
    var recentSearches: [RecentSearchItem] = []
    var isSearching: Bool = false
    var errorMessage: String? = nil
}
