import Combine
import Foundation
import SwiftUI

// MARK: - Estate Detail State

struct EstateDetailState {
    var estate: EstateDetailResponse?
    var similarEstates: [EstateSummaryResponse] = []
    var isLoading: Bool = false
    var isLikeLoading: Bool = false
    var errorMessage: String?

    // 채팅 관련 상태
    var isCreatingChatRoom: Bool = false
    var chatRoomError: String?
    var createdChatRoom: ChatRoomResponse?

    // 예약/결제 관련 상태
    var isReservationLoading: Bool = false
    var reservationError: String?
    var createdOrder: OrderCreateResponse?
    var showPaymentWebView: Bool = false
    var showReservationSuccess: Bool = false

    var isLiked: Bool {
        estate?.is_liked ?? false
    }
}

// MARK: - Estate Detail Intent

@MainActor
final class EstateDetailIntent: ObservableObject {
    @Published private(set) var state = EstateDetailState()

    // Binding for View
    var showPaymentWebViewBinding: Binding<Bool> {
        Binding(
            get: { self.state.showPaymentWebView },
            set: { self.state.showPaymentWebView = $0 }
        )
    }

    var showReservationSuccessBinding: Binding<Bool> {
        Binding(
            get: { self.state.showReservationSuccess },
            set: { self.state.showReservationSuccess = $0 }
        )
    }

    private let estateRepository: EstateRepository
    private let chatRepository: ChatRepository
    private let orderRepository: OrderRepository
    private let paymentRepository: PaymentRepository
    private let estateId: String

    init(
        estateId: String,
        estateRepository: EstateRepository? = nil,
        chatRepository: ChatRepository? = nil,
        orderRepository: OrderRepository? = nil,
        paymentRepository: PaymentRepository? = nil
    ) {
        self.estateId = estateId
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
        self.chatRepository = chatRepository ?? DIContainer.shared.makeChatRepository()
        self.orderRepository = orderRepository ?? DIContainer.shared.makeOrderRepository()
        self.paymentRepository = paymentRepository ?? DIContainer.shared.makePaymentRepository()
    }

    // MARK: - Actions

    func loadDetail() async {
        print("🔍 [DEBUG] loadDetail 시작 - estateId: \(estateId)")
        state.isLoading = true
        state.errorMessage = nil

        do {
            async let detail = estateRepository.fetchEstateDetail(estateId: estateId)
            async let similar = estateRepository.fetchSimilarEstates()

            let detailResult = try await detail
            print("✅ [DEBUG] 상세 데이터 수신: \(detailResult.title)")
            print("✅ [DEBUG] files 개수: \(detailResult.files.count)")
            print("✅ [DEBUG] 옵션 데이터:")
            print("  - option1 (에어컨): \(detailResult.options.option1)")
            print("  - option2 (냉장고): \(detailResult.options.option2)")
            print("  - option3 (세탁기): \(detailResult.options.option3)")
            print("  - option4: \(detailResult.options.option4)")
            print("  - option5: \(detailResult.options.option5)")
            print("  - option6 (전자레인지): \(detailResult.options.option6)")
            print("  - option7: \(detailResult.options.option7)")
            print("  - option8: \(detailResult.options.option8)")
            print("  - option9 (옷장): \(detailResult.options.option9)")
            print("  - option10 (신발장): \(detailResult.options.option10)")
            state.estate = detailResult
            state.similarEstates = (try? await similar) ?? []
            print("✅ [DEBUG] 유사매물 개수: \(state.similarEstates.count)")
        } catch let error as NetworkError {
            print("❌ [DEBUG] NetworkError: \(error.message)")
            state.errorMessage = error.message
        } catch {
            print("❌ [DEBUG] Unknown Error: \(error)")
            state.errorMessage = "매물 정보를 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
        print("🔍 [DEBUG] loadDetail 종료 - estate: \(state.estate != nil ? "있음" : "없음"), error: \(state.errorMessage ?? "없음")")
    }

    func toggleLike() async {
        guard let estate = state.estate else { return }

        state.isLikeLoading = true

        do {
            _ = try await estateRepository.toggleLike(
                estateId: estateId,
                like: !estate.is_liked
            )
            // 상태 업데이트를 위해 다시 로드
            await loadDetail()
        } catch {
            // 좋아요 실패는 조용히 처리
        }

        state.isLikeLoading = false
    }

    func createChatRoomWithAgent() async {
        guard let estate = state.estate else { return }

        state.isCreatingChatRoom = true
        state.chatRoomError = nil
        state.createdChatRoom = nil

        do {
            let room = try await chatRepository.createOrGetChatRoom(
                opponentId: estate.creator.user_id
            )
            state.createdChatRoom = room
        } catch let error as NetworkError {
            state.chatRoomError = error.message
        } catch {
            state.chatRoomError = "채팅방 생성에 실패했습니다."
        }

        state.isCreatingChatRoom = false
    }

    func clearChatRoomError() {
        state.chatRoomError = nil
    }

    // MARK: - Reservation Actions

    /// 주문 생성 (1단계: 예약하기 버튼 클릭)
    func createOrder() async {
        guard let estate = state.estate else { return }
        guard !estate.is_reserved else { return }

        state.isReservationLoading = true
        state.reservationError = nil

        do {
            let order = try await orderRepository.createOrder(
                estateId: estateId,
                totalPrice: estate.reservation_price
            )
            state.createdOrder = order
            state.showPaymentWebView = true
        } catch let error as NetworkError {
            handleReservationError(error)
        } catch {
            state.reservationError = "주문 생성 중 오류가 발생했습니다."
        }

        state.isReservationLoading = false
    }

    /// 결제 검증 (2단계: 포트원 결제 완료 후)
    func validatePayment(impUid: String) async {
        state.isReservationLoading = true
        state.reservationError = nil
        state.showPaymentWebView = false

        do {
            _ = try await paymentRepository.validatePayment(impUid: impUid)
            // 검증 성공 - 매물 정보 다시 로드 (is_reserved 업데이트)
            await loadDetail()
            state.showReservationSuccess = true
        } catch let error as NetworkError {
            handleReservationError(error)
        } catch {
            state.reservationError = "결제 검증 중 오류가 발생했습니다."
        }

        state.isReservationLoading = false
    }

    /// 결제 취소
    func cancelPayment() {
        state.showPaymentWebView = false
        state.createdOrder = nil
        state.reservationError = "결제가 취소되었습니다."
    }

    /// 예약 완료 모달 닫기
    func closeReservationSuccess() {
        state.showReservationSuccess = false
    }

    /// 에러 메시지 초기화
    func clearReservationError() {
        state.reservationError = nil
    }

    /// 예약 에러 처리
    private func handleReservationError(_ error: NetworkError) {
        switch error {
        case .badRequest:
            state.reservationError = "필수값을 채워주세요."
        case .notFound:
            state.reservationError = "주문번호를 다시 확인해주세요."
        case .conflict:
            state.reservationError = "이미 예약된 매물입니다."
        case .notParticipant:
            state.reservationError = "주문자 정보가 일치하지 않습니다."
        case .unauthorized:
            state.reservationError = "로그인이 필요합니다."
        default:
            state.reservationError = error.message
        }
    }
}
