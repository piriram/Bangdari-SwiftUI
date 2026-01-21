import Combine
import CoreLocation
import Foundation

// MARK: - Community List State

struct CommunityListState {
    var posts: [PostSummaryResponse] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?
    var nextCursor: String? = nil
    var hasMore: Bool = true

    // 위치
    var currentLocation: CLLocationCoordinate2D?
    var maxDistance: Int = 5000 // 5km

    // 검색
    var searchQuery: String = ""
}

// MARK: - Community List Intent

@MainActor
final class CommunityListIntent: ObservableObject {
    @Published private(set) var state = CommunityListState()

    private let postRepository: PostRepository
    private let locationManager = CLLocationManager()

    init(postRepository: PostRepository? = nil) {
        self.postRepository = postRepository ?? DIContainer.shared.makePostRepository()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        if let location = locationManager.location {
            state.currentLocation = location.coordinate
        }
    }

    // MARK: - Actions

    func loadPosts() async {
        state.isLoading = true
        state.errorMessage = nil
        state.posts = []
        state.nextCursor = nil
        state.hasMore = true

        // 위치 기반 조회
        if let location = state.currentLocation ?? locationManager.location?.coordinate {
            do {
                let posts = try await postRepository.fetchPostsByLocation(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    maxDistance: state.maxDistance,
                    category: nil
                )
                state.posts = posts
                state.nextCursor = nil
                state.hasMore = false
            } catch let error as NetworkError {
                state.errorMessage = error.message
            } catch {
                state.errorMessage = "게시글을 불러오는 중 오류가 발생했습니다."
            }
        } else {
            state.errorMessage = "위치 정보를 가져올 수 없습니다."
        }

        state.isLoading = false
    }

    func searchPosts() async {
        guard !state.searchQuery.isEmpty else {
            await loadPosts()
            return
        }

        state.isLoading = true
        state.errorMessage = nil
        state.posts = []
        state.nextCursor = nil

        do {
            let response = try await postRepository.searchPosts(
                title: state.searchQuery,
                next: nil,
                limit: 20
            )
            state.posts = response.data
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "검색 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func loadMore() async {
        guard !state.isLoadingMore, state.hasMore, let cursor = state.nextCursor else { return }

        state.isLoadingMore = true

        do {
            let response = try await postRepository.searchPosts(
                title: state.searchQuery.isEmpty ? nil : state.searchQuery,
                next: cursor,
                limit: 20
            )
            state.posts.append(contentsOf: response.data)
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
        } catch {
            // 페이지네이션 에러는 조용히 처리
        }

        state.isLoadingMore = false
    }

    func updateSearchQuery(_ query: String) {
        state.searchQuery = query
    }

    func refresh() async {
        if state.searchQuery.isEmpty {
            await loadPosts()
        } else {
            await searchPosts()
        }
    }
}
