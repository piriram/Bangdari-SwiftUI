import Kingfisher
import SwiftUI

// MARK: - Estate Detail View

struct EstateDetailView: View {
    @StateObject private var intent: EstateDetailIntent
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0
    @State private var navigateToChatRoom = false

    // MARK: - Constants

    private let imageAspectRatio: CGFloat = 4 / 3
    private var imageHeight: CGFloat {
        UIScreen.main.bounds.width / imageAspectRatio
    }

    init(estateId: String) {
        _intent = StateObject(wrappedValue: EstateDetailIntent(estateId: estateId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            if let estate = intent.state.estate {
                CustomNavigationBar(onBack: { dismiss() }) {
                    Text(estate.title)
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray90)
                        .lineLimit(1)
                } trailing: {
                    Button {
                        Task { await intent.toggleLike() }
                    } label: {
                        DSIconView(intent.state.isLiked ? .likeFill : .likeEmpty, size: 24, renderingMode: .template)
                            .foregroundColor(intent.state.isLiked ? .red : .gray60)
                    }
                    .disabled(intent.state.isLikeLoading)
                }
            } else {
                CustomNavigationBar(onBack: { dismiss() }) {
                    Text("매물 상세")
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray90)
                }
            }

            // 콘텐츠
            Group {
                if let estate = intent.state.estate {
                    detailContent(estate)
                } else if let error = intent.state.errorMessage {
                    errorView(error)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await intent.loadDetail()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ estate: EstateDetailResponse) -> some View {
        ZStack {
            // 배경: gray15 단일 톤
            Color.gray15.ignoresSafeArea()

            // 스크롤 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Z2: Primary Media Layer
                    imageCarousel(estate.files)

                    // Z3: Core Information Layer
                    statusRow(estate)
                    coreInfoSection(estate)

                    // Z4: Detail Content Layer
                    optionSection(estate.options)
                    conditionRow(estate)
                    descriptionSection(estate)

                    // Z5: Related Information Layer
                    if !intent.state.similarEstates.isEmpty {
                        similarEstatesSection
                    }

                    // Z5b: Comments Section
                    commentsSection(estate)

                    agentSection(estate.creator)

                    // 하단 여백 (CTA 영역)
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Z6: Persistent Action Layer
            bottomCTA(estate)
        }
        .background(
            NavigationLink(
                destination: chatRoomDestination(),
                isActive: $navigateToChatRoom
            ) {
                EmptyView()
            }
            .opacity(0)
        )
        .alert("채팅방 생성 실패", isPresented: .constant(intent.state.chatRoomError != nil)) {
            Button("확인") {
                intent.clearChatRoomError()
            }
        } message: {
            if let error = intent.state.chatRoomError {
                Text(error)
            }
        }
        .sheet(isPresented: intent.showPaymentWebViewBinding) {
            if let order = intent.state.createdOrder,
               let estate = intent.state.estate {
                PaymentWebView(
                    order: order,
                    estateName: estate.title,
                    onSuccess: { impUid in
                        Task { await intent.validatePayment(impUid: impUid) }
                    },
                    onCancel: { intent.cancelPayment() }
                )
            }
        }
        .sheet(isPresented: intent.showReservationSuccessBinding) {
            ReservationSuccessView {
                intent.closeReservationSuccess()
            }
        }
        .alert("예약 실패", isPresented: .constant(intent.state.reservationError != nil)) {
            Button("확인") { intent.clearReservationError() }
        } message: {
            if let error = intent.state.reservationError {
                Text(error)
            }
        }
    }

    // MARK: - Z2: Primary Media (Image Carousel)

    private func imageCarousel(_ files: [String]) -> some View {
        ZStack(alignment: .bottom) {
            // 이미지 캐러셀
            TabView(selection: $currentImageIndex) {
                ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                    KFImage.auth(url: URL(string: APIConfig.baseURL + "/" + file))
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width)
                        .frame(height: imageHeight)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: imageHeight)

            // 하단 영역: Page Indicator + Image Count Badge
            HStack {
                Spacer()

                // Page Indicator (중앙)
                HStack(spacing: 6) {
                    ForEach(0..<max(files.count, 1), id: \.self) { index in
                        Circle()
                            .fill(index == currentImageIndex ? Color.gray90 : Color.gray45)
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                // Image Count Badge (우측 하단)
                Text("\(currentImageIndex + 1)/\(max(files.count, 1))")
                    .font(.pretendard(.caption2, .medium))
                    .foregroundColor(.gray0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray100.opacity(0.4))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Z3: Status Row (조회수 / 안심 배지)

    private func statusRow(_ estate: EstateDetailResponse) -> some View {
        HStack(spacing: 8) {
            // 조회수 (왼쪽)
            Text("\(estate.like_count)명이 함께 보는 중")
                .font(.pretendard(.caption1))
                .foregroundColor(.gray60)

            Spacer()

            // 안심매물 배지 (오른쪽)
            if estate.is_safe_estate {
                HStack(spacing: 4) {
                    DSIconView(.safety, size: 14, renderingMode: .template)
                    Text("구매자 안심매물")
                        .font(.pretendard(.caption1))
                }
                .foregroundColor(.deepCoast)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    Capsule()
                        .stroke(Color.deepCoast, lineWidth: 1)
                )
                .background(Color.gray0)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Z3: Core Info Section (주소 / 가격)

    private func coreInfoSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 주소
            Text(estate.title)
                .font(.pretendard(.body3))
                .foregroundColor(.gray75)

            // 가격 (가장 강조)
            if estate.monthly_rent > 0 {
                Text("월세 \(formatPrice(estate.deposit)) / \(estate.monthly_rent)")
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray90)
            } else {
                Text("전세 \(formatPrice(estate.deposit))")
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray90)
            }

            // 부가정보 (관리비 / 면적)
            HStack(spacing: 4) {
                if estate.maintenance_fee > 0 {
                    Text("관리비 \(estate.maintenance_fee)만원")
                } else {
                    Text("관리비 별도")
                }
                Text("·")
                Text("\(String(format: "%.1f", estate.area))m²")
                Text("·")
                Text(estate.floors)
            }
            .font(.pretendard(.caption1))
            .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Z4: Option Section

    private func optionSection(_ options: EstateOptions) -> some View {
        let allOptions = [
            ("에어컨", "OptionAirConditioner", options.option1),
            ("냉장고", "OptionRefrigerator", options.option2),
            ("세탁기", "OptionWashingMachine", options.option3),
            ("전자레인지", "OptionMicrowave", options.option6),
            ("옷장", "OptionCloset", options.option9),
            ("신발장", "OptionShoeCabinet", options.option10),
            ("싱크대", "OptionSink", options.option4),
            ("TV", "OptionTelevision", options.option5)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("옵션")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            // 옵션 그리드 (gray0 배경)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(allOptions, id: \.0) { name, icon, enabled in
                    VStack(spacing: 6) {
                        Image(icon)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(enabled ? .gray90 : .gray45)

                        Text(name)
                            .font(.pretendard(.caption1))
                            .foregroundColor(enabled ? .gray75 : .gray45)
                    }
                }
            }
            .padding(16)
            .background(Color.gray0)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Z4: Condition Row (주차 가능 등)

    private func conditionRow(_ estate: EstateDetailResponse) -> some View {
        HStack(spacing: 8) {
            if estate.parking_count > 0 {
                conditionChip(icon: "IconParking", text: "주차 가능")
            }
            // 추가 조건들이 있으면 여기에 추가
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func conditionChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .frame(width: 16, height: 16)
            Text(text)
                .font(.pretendard(.caption1))
        }
        .foregroundColor(.gray75)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray30)
        .clipShape(Capsule())
    }

    // MARK: - Z4: Description Section

    private func descriptionSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 설명")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            Text(estate.description.isEmpty ? estate.introduction : estate.description)
                .font(.pretendard(.body2))
                .foregroundColor(.gray75)
                .lineSpacing(8)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Z5: Similar Estates Section

    private var similarEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("유사한 매물")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(intent.state.similarEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            similarEstateCard(estate)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
    }

    private func similarEstateCard(_ estate: EstateSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 (1:1 비율, 상단 radius)
            KFImage.auth(url: similarEstateImageURL(estate))
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])

            // 텍스트 영역
            VStack(alignment: .leading, spacing: 4) {
                Text(similarPriceText(estate))
                    .font(.pretendard(.body2, .bold))
                    .foregroundColor(.gray90)

                Text("\(String(format: "%.0f", estate.area))m² · \(estate.category)")
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
            .padding(10)
        }
        .frame(width: 160)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - Z5b: Comments Section

    private func commentsSection(_ estate: EstateDetailResponse) -> some View {
        NavigationLink(destination: EstateCommentView(estateId: estate.estate_id)) {
            HStack(spacing: 12) {
                // 댓글 아이콘
                Image(systemName: "bubble.left")
                    .font(.system(size: 20))
                    .foregroundColor(.deepCoast)

                // 댓글 개수
                Text("댓글 \(estate.comments.count)개")
                    .font(.pretendard(.body2, .medium))
                    .foregroundColor(.gray90)

                Spacer()

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.gray30)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Z5: Agent Section

    private func agentSection(_ creator: UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("중개사 정보")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            HStack(spacing: 12) {
                // 아바타
                KFImage.auth(url: profileImageURL(creator.profileImage))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .background(Color.gray30)
                    .clipShape(Circle())

                // 이름 / 설명
                VStack(alignment: .leading, spacing: 2) {
                    Text(creator.nick)
                        .font(.pretendard(.body2, .bold))
                        .foregroundColor(.gray90)

                    Text("공인중개사")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray60)
                }

                Spacer()

                // 연락 버튼들
                HStack(spacing: 8) {
                    contactButton(icon: .call)
                    contactButton(icon: .chat)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func contactButton(icon: ContactIcon) -> some View {
        Button {
            if icon == .chat {
                Task {
                    await intent.createChatRoomWithAgent()
                    if intent.state.createdChatRoom != nil {
                        navigateToChatRoom = true
                    }
                }
            } else if icon == .call {
                // TODO: 전화 걸기 기능
            }
        } label: {
            Image.contactIcon(icon)
                .frame(width: 18, height: 18)
                .frame(width: 40, height: 40)
                .background(Color.deepCream)
                .cornerRadius(10)
                .opacity(intent.state.isCreatingChatRoom ? 0.5 : 1.0)
        }
        .disabled(intent.state.isCreatingChatRoom)
    }

    // MARK: - Z6: Bottom CTA

    private func bottomCTA(_ estate: EstateDetailResponse) -> some View {
        HStack(spacing: 12) {
            // 찜 버튼
            Button {
                Task { await intent.toggleLike() }
            } label: {
                DSIconView(intent.state.isLiked ? .likeFill : .likeEmpty, size: 24, renderingMode: .template)
                    .foregroundColor(intent.state.isLiked ? .red : .gray75)
                    .frame(width: 56, height: 56)
                    .background(Color.gray30)
                    .cornerRadius(14)
            }
            .disabled(intent.state.isLikeLoading)

            // CTA 버튼
            Button {
                Task { await intent.createOrder() }
            } label: {
                if intent.state.isReservationLoading {
                    ProgressView()
                        .tint(.gray0)
                } else {
                    Text(estate.is_reserved ? "예약완료" : "예약하기")
                        .font(.pretendard(.body1, .bold))
                        .foregroundColor(estate.is_reserved ? .gray60 : .gray0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(estate.is_reserved ? Color.gray30 : Color.deepCream)
            .cornerRadius(14)
            .disabled(estate.is_reserved || intent.state.isReservationLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray15)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.pretendard(.body2))
                .foregroundColor(.gray60)

            Button("다시 시도") {
                Task { await intent.loadDetail() }
            }
            .font(.pretendard(.body2, .semiBold))
            .foregroundColor(.deepCoast)
        }
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let billion = price / 10000
            let remainder = price % 10000
            return remainder == 0 ? "\(billion)억" : "\(billion)억 \(remainder)"
        }
        return "\(price)"
    }

    private func profileImageURL(_ path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: APIConfig.baseURL + "/" + path)
    }

    private func similarEstateImageURL(_ estate: EstateSummaryResponse) -> URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private func similarPriceText(_ estate: EstateSummaryResponse) -> String {
        if estate.monthly_rent > 0 {
            return "월세 \(estate.deposit)/\(estate.monthly_rent)"
        }
        return "전세 \(estate.deposit)"
    }

    @ViewBuilder
    private func chatRoomDestination() -> some View {
        if let room = intent.state.createdChatRoom,
           let estate = intent.state.estate {
            ChatRoomView(
                roomId: room.room_id,
                opponent: estate.creator
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        EstateDetailView(estateId: "test")
    }
}
