import SwiftUI

// MARK: - Estate Detail View

struct EstateDetailView: View {
    @StateObject private var intent: EstateDetailIntent
    @Environment(\.dismiss) private var dismiss

    init(estateId: String) {
        _intent = StateObject(wrappedValue: EstateDetailIntent(estateId: estateId))
    }

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.estate == nil {
                ProgressView()
            } else if let estate = intent.state.estate {
                detailContent(estate)
            } else if let error = intent.state.errorMessage {
                errorView(error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                likeButton
            }
        }
        .task {
            await intent.loadDetail()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ estate: EstateDetailResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 이미지 갤러리
                imageGallery(estate.files)

                VStack(alignment: .leading, spacing: 16) {
                    // 기본 정보
                    basicInfo(estate)

                    Divider()

                    // 가격 정보
                    priceInfo(estate)

                    Divider()

                    // 옵션
                    optionsSection(estate.options)

                    Divider()

                    // 중개인 정보
                    creatorInfo(estate.creator)

                    // 댓글
                    if !estate.comments.isEmpty {
                        Divider()
                        commentsSection(estate.comments)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Image Gallery

    private func imageGallery(_ files: [String]) -> some View {
        TabView {
            ForEach(files, id: \.self) { file in
                AsyncImage(url: URL(string: Secrets.baseURL + "/" + file)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
        }
        .frame(height: 250)
        .tabViewStyle(.page)
    }

    // MARK: - Basic Info

    private func basicInfo(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(estate.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brown.opacity(0.1))
                    .foregroundColor(.brown)
                    .cornerRadius(4)

                if estate.is_safe_estate {
                    Text("안전매물")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }

                if estate.is_reserved {
                    Text("예약중")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }

            Text(estate.title)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(estate.floors) · \(String(format: "%.1f", estate.area))㎡")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Price Info

    private func priceInfo(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("가격 정보")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("보증금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatPrice(estate.deposit))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if estate.monthly_rent > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("월세")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPrice(estate.monthly_rent))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Options Section

    private func optionsSection(_ options: EstateOptions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("옵션")
                .font(.headline)

            let enabled = options.enabledOptions
            if enabled.isEmpty {
                Text("옵션 없음")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(enabled, id: \.self) { option in
                        Text(option)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Creator Info

    private func creatorInfo(_ creator: UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("중개인")
                .font(.headline)

            HStack(spacing: 12) {
                AsyncImage(url: profileImageURL(creator.profileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                Text(creator.nick)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button("채팅하기") {
                    // TODO: 채팅방 생성 후 이동
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Comments Section

    private func commentsSection(_ comments: [EstateComment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글 \(comments.count)")
                .font(.headline)

            ForEach(comments, id: \.comment_id) { comment in
                commentRow(comment)
            }
        }
    }

    private func commentRow(_ comment: EstateComment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.creator.nick)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(comment.createdAt.prefix(10))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(comment.content)
                .font(.subheadline)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Like Button

    private var likeButton: some View {
        Button {
            Task { await intent.toggleLike() }
        } label: {
            Image(systemName: intent.state.isLiked ? "heart.fill" : "heart")
                .foregroundColor(intent.state.isLiked ? .red : .gray)
        }
        .disabled(intent.state.isLikeLoading)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("다시 시도") {
                Task { await intent.loadDetail() }
            }
            .buttonStyle(.bordered)
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
                return "\(billion)억 \(remainder)만"
            }
        }
        return "\(price)만"
    }

    private func profileImageURL(_ path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: Secrets.baseURL + "/" + path)
    }
}

#Preview {
    NavigationStack {
        EstateDetailView(estateId: "test")
    }
}
