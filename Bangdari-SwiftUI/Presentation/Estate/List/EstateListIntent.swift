import Combine
import CoreLocation
import Foundation

// MARK: - Estate List State

struct EstateListState {
    var estates: [EstateSummaryResponse] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?

    // 페이지네이션
    var nextCursor: String? = nil
    var hasMore: Bool = true

    // 필터
    var selectedCategory: String? = nil

    // 위치
    var currentLocation: CLLocationCoordinate2D?
    var maxDistance: Int = 5000  // 기본 5km

    // 배너
    var banners: [Banner] = []
    var isBannersLoading: Bool = false
    var bannerLoadError: String?
}

// MARK: - Estate List Intent

@MainActor
final class EstateListIntent: ObservableObject {
    @Published private(set) var state = EstateListState()

    private let estateRepository: EstateRepository
    private let locationManager = CLLocationManager()

    init(estateRepository: EstateRepository? = nil) {
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
    }

    // MARK: - Actions

    func loadEstates(at location: CLLocationCoordinate2D) async {
        state.isLoading = true
        state.errorMessage = nil
        state.currentLocation = location

        // 매물과 배너를 병렬로 로드
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let estates = try await self.estateRepository.fetchEstatesByLocation(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        maxDistance: self.state.maxDistance,
                        category: self.state.selectedCategory
                    )
                    await MainActor.run {
                        self.state.estates = estates
                    }
                } catch let error as NetworkError {
                    await MainActor.run {
                        self.state.errorMessage = error.message
                    }
                } catch {
                    await MainActor.run {
                        self.state.errorMessage = "매물을 불러오는 중 오류가 발생했습니다."
                    }
                }
            }

            group.addTask {
                await self.loadBanners()
            }
        }

        state.isLoading = false
    }

    func loadMyLikedEstates() async {
        state.isLoading = true
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasMore = true

        // 매물과 배너를 병렬로 로드
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let response = try await self.estateRepository.fetchMyLikedEstates(
                        next: nil,
                        limit: 20,
                        category: self.state.selectedCategory
                    )
                    await MainActor.run {
                        self.state.estates = response.data
                        self.state.nextCursor = response.next_cursor
                        self.state.hasMore = response.hasMore
                    }
                } catch let error as NetworkError {
                    await MainActor.run {
                        self.state.errorMessage = error.message
                    }
                } catch {
                    await MainActor.run {
                        self.state.errorMessage = "좋아요 매물을 불러오는 중 오류가 발생했습니다."
                    }
                }
            }

            group.addTask {
                await self.loadBanners()
            }
        }

        state.isLoading = false
    }

    func loadMoreLikedEstates() async {
        guard !state.isLoadingMore, state.hasMore, let cursor = state.nextCursor else { return }

        state.isLoadingMore = true

        do {
            let response = try await estateRepository.fetchMyLikedEstates(
                next: cursor,
                limit: 20,
                category: state.selectedCategory
            )
            state.estates.append(contentsOf: response.data)
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
        } catch {
            // 추가 로딩 실패는 조용히 처리
        }

        state.isLoadingMore = false
    }

    func setCategory(_ category: String?) {
        state.selectedCategory = category
    }

    func setMaxDistance(_ distance: Int) {
        state.maxDistance = distance
    }

    func refresh() async {
        if let location = state.currentLocation {
            await loadEstates(at: location)
        }
    }

    func loadBanners() async {
        state.isBannersLoading = true
        state.bannerLoadError = nil

        print("🎯 [BANNER] API 호출 시작: GET /v1/banners/main")

        do {
            let banners = try await estateRepository.fetchMainBanners()

            print("✅ [BANNER] API 성공 - 받은 배너 개수: \(banners.count)")

            // 각 배너의 상세 정보 로깅
            for (index, banner) in banners.enumerated() {
                print("📌 [BANNER #\(index + 1)]")
                print("  - Title: \(banner.title)")
                print("  - Image: '\(banner.image)' (길이: \(banner.image.count))")

                // URL 구성 테스트
                let testURL: URL?
                if banner.image.hasPrefix("http") {
                    testURL = URL(string: banner.image)
                } else {
                    testURL = URL(string: Secrets.baseURL + "/" + banner.image)
                }
                print("  - 구성된 URL: \(testURL?.absoluteString ?? "❌ INVALID")")
            }

            state.banners = banners
        } catch {
            // 배너 로드 실패는 조용히 처리 (매물 리스트는 정상 표시)
            state.bannerLoadError = error.localizedDescription
            print("❌ [BANNER] API 실패: \(error)")
        }

        state.isBannersLoading = false
        print("🏁 [BANNER] 로딩 완료 - state.banners.count: \(state.banners.count)")
    }
}
