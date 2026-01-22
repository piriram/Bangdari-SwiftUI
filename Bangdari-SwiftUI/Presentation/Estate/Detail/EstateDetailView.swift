import Kingfisher
import SwiftUI

// MARK: - Estate Detail View

struct EstateDetailView: View {
    @StateObject private var intent: EstateDetailIntent
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0

    init(estateId: String) {
        _intent = StateObject(wrappedValue: EstateDetailIntent(estateId: estateId))
    }

    var body: some View {
        Group {
            if let estate = intent.state.estate {
                detailContent(estate)
            } else if let error = intent.state.errorMessage {
                errorView(error)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(dsIcon: .chevron)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray90)
                }
            }

            ToolbarItem(placement: .principal) {
                Text(intent.state.estate?.title ?? "")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await intent.toggleLike() }
                } label: {
                    Image(dsIcon: intent.state.isLiked ? .likeFill : .likeEmpty)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(intent.state.isLiked ? .red : .gray75)
                }
                .disabled(intent.state.isLikeLoading)
            }
        }
        .task {
            await intent.loadDetail()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ estate: EstateDetailResponse) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 이미지 갤러리
                    imageCarousel(estate.files)

                    VStack(alignment: .leading, spacing: 20) {
                        // 상태 뱃지 + 업데이트 시간
                        statusBadgeSection(estate)

                        // 주소 정보
                        addressInfo(estate)

                        // 가격 정보 (강조)
                        priceSection(estate)

                        // 옵션 그리드
                        optionGrid(estate.options)

                        // 중개인 정보
                        creatorInfo(estate.creator)

                        // 유사 매물
                        if !intent.state.similarEstates.isEmpty {
                            similarEstatesSection
                        }

                        // 댓글
                        if !estate.comments.isEmpty {
                            commentsSection(estate.comments)
                        }

                        // 하단 여백 (CTA 버튼 영역)
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }

            // 하단 고정 CTA
            bottomActionBar(estate)
        }
        .background(Color.gray0)
    }

    // MARK: - Image Carousel

    private func imageCarousel(_ files: [String]) -> some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                    KFImage.auth(url: URL(string: APIConfig.baseURL + "/" + file))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color.gray15)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(4/3, contentMode: .fit)

            // 오버레이 요소들
            HStack {
                // 실시간 정보
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                    Text("34명이 함께 보는 중")
                        .font(.pretendardCaption2)
                }
                .foregroundColor(.gray0)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)

                Spacer()

                // 이미지 카운트
                Text("\(currentImageIndex + 1) / \(files.count)")
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Status Badge Section

    private func statusBadgeSection(_ estate: EstateDetailResponse) -> some View {
        HStack {
            if estate.is_safe_estate {
                HStack(spacing: 6) {
                    Image(dsIcon: .safety)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("구매자 안심매물")
                        .font(.pretendardCaption1)
                }
                .foregroundColor(.deepCoast)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.brightCoast.opacity(0.2))
                .clipShape(Capsule())
            }

            if estate.is_reserved {
                Text("예약중")
                    .font(.pretendardCaption1)
                    .foregroundColor(.deepWood)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brightCream)
                    .clipShape(Capsule())
            }

            Spacer()

            // 업데이트 시점
            Text(formatDate(estate.updatedAt))
                .font(.pretendardCaption1)
                .foregroundColor(.gray60)
        }
    }

    // MARK: - Address Info

    private func addressInfo(_ estate: EstateDetailResponse) -> some View {
        Text("서울 영등포구 선유로9길 30") // TODO: 실제 주소 데이터 연동
            .font(.pretendardBody3)
            .foregroundColor(.gray75)
    }

    // MARK: - Price Section

    private func priceSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 메인 가격
            if estate.monthly_rent > 0 {
                Text("월세 \(formatPrice(estate.deposit)) / \(estate.monthly_rent)")
                    .font(.pretendardTitle1)
                    .foregroundColor(.gray90)
            } else {
                Text("전세 \(formatPrice(estate.deposit))")
                    .font(.pretendardTitle1)
                    .foregroundColor(.gray90)
            }

            // 보조 정보
            Text("관리비 별도 · \(String(format: "%.1f", estate.area))m² · \(estate.floors)")
                .font(.pretendardBody3)
                .foregroundColor(.gray75)
        }
    }

    // MARK: - Option Grid

    private func optionGrid(_ options: EstateOptions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let allOptions = [
                ("냉장고", "OptionRefrigerator", options.option1),
                ("세탁기", "OptionWashingMachine", options.option2),
                ("에어컨", "OptionAirConditioner", options.option3),
                ("옷장", "OptionCloset", options.option4),
                ("신발장", "OptionShoeCabinet", options.option5),
                ("전자레인지", "OptionMicrowave", options.option6),
                ("싱크대", "OptionSink", options.option7),
                ("TV", "OptionTelevision", options.option8)
            ]

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(allOptions, id: \.0) { name, icon, enabled in
                    optionItem(name: name, icon: icon, enabled: enabled)
                }
            }
            .padding(16)
            .background(Color.gray15)
            .cornerRadius(12)
        }
    }

    private func optionItem(name: String, icon: String, enabled: Bool) -> some View {
        VStack(spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .opacity(enabled ? 1.0 : 0.3)

            Text(name)
                .font(.pretendardCaption2)
                .foregroundColor(enabled ? .gray90 : .gray45)
        }
    }

    // MARK: - Creator Info

    private func creatorInfo(_ creator: UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("중개인")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)

            HStack(spacing: 12) {
                KFImage.auth(url: profileImageURL(creator.profileImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .background(Color.gray15)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(creator.nick)
                        .font(.pretendardBody2Bold)
                        .foregroundColor(.gray90)
                }

                Spacer()
            }
        }
    }

    // MARK: - Similar Estates Section

    private var similarEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("유사한 매물")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(intent.state.similarEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            similarEstateCard(estate)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func similarEstateCard(_ estate: EstateSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage.auth(url: similarEstateImageURL(estate))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 100)
                .background(Color.gray15)
                .clipped()
                .cornerRadius(8)

            Text(estate.category)
                .font(.pretendardCaption2)
                .foregroundColor(.deepWood)

            Text(estate.title)
                .font(.pretendardCaption1)
                .foregroundColor(.gray90)
                .lineLimit(1)

            Text(similarPriceText(estate))
                .font(.pretendardCaption1)
                .foregroundColor(.gray75)
        }
        .frame(width: 140)
    }

    // MARK: - Comments Section

    private func commentsSection(_ comments: [EstateComment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글 \(comments.count)")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)

            ForEach(comments, id: \.comment_id) { comment in
                commentRow(comment)
            }
        }
    }

    private func commentRow(_ comment: EstateComment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.creator.nick)
                    .font(.pretendardBody3)
                    .foregroundColor(.gray90)
                Spacer()
                Text(String(comment.createdAt.prefix(10)))
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
            }

            Text(comment.content)
                .font(.pretendardBody3)
                .foregroundColor(.gray75)
        }
        .padding(12)
        .background(Color.gray15)
        .cornerRadius(8)
    }

    // MARK: - Bottom Action Bar

    private func bottomActionBar(_ estate: EstateDetailResponse) -> some View {
        HStack(spacing: 12) {
            // 관심 버튼
            Button {
                Task { await intent.toggleLike() }
            } label: {
                Image(dsIcon: intent.state.isLiked ? .likeFill : .likeEmpty)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(intent.state.isLiked ? .red : .gray75)
                    .frame(width: 52, height: 52)
                    .background(Color.gray15)
                    .clipShape(Circle())
            }
            .disabled(intent.state.isLikeLoading)

            // 예약하기 버튼
            Button {
                // TODO: 예약 플로우
            } label: {
                Text("예약하기")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(estate.is_reserved ? Color.gray30 : Color.deepCream)
                    .cornerRadius(12)
            }
            .disabled(estate.is_reserved)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.gray0
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
        )
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.pretendardBody2)
                .foregroundColor(.gray60)

            Button("다시 시도") {
                Task { await intent.loadDetail() }
            }
            .font(.pretendardBody2Bold)
            .foregroundColor(.deepCoast)
        }
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let billion = price / 10000
            let remainder = price % 10000
            if remainder == 0 {
                return "\(billion)억"
            } else {
                return "\(billion)억 \(remainder)"
            }
        }
        return "\(price)"
    }

    private func formatDate(_ dateString: String) -> String {
        // 간단한 날짜 포맷 (예: "2일 전")
        return "2일 전" // TODO: 실제 날짜 계산
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
            return "\(estate.deposit)/\(estate.monthly_rent)"
        } else {
            return "전세 \(estate.deposit)"
        }
    }
}

#Preview {
    NavigationStack {
        EstateDetailView(estateId: "test")
    }
}
