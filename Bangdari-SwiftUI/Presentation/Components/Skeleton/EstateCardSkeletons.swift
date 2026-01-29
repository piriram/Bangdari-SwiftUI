import SwiftUI

// MARK: - Estate Card Small Skeleton (오늘의 매물용)

struct EstateCardSmallSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일 영역
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray30)
                .frame(width: 88, height: 88)
                .skeleton()

            // 텍스트 영역
            VStack(alignment: .leading, spacing: 6) {
                // 카테고리 태그
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 60, height: 16)
                    .skeleton()

                // 가격
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 100, height: 20)
                    .skeleton()

                // 면적
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 80, height: 14)
                    .skeleton()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(height: 112)
        .background(Color.gray15)
        .cornerRadius(12)
    }
}

// MARK: - Estate Card Large Skeleton (HOT 매물용)

struct EstateCardLargeSkeleton: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // 배경
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray30)
                    .skeleton()

                // 좌상단 HOT 아이콘 영역
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.gray45)
                            .frame(width: 24, height: 24)

                        Spacer()
                    }
                    Spacer()
                }
                .padding(12)

                // 우상단 텍스트 영역
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            // 제목
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray45)
                                .frame(width: 120, height: 14)

                            // 가격
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray45)
                                .frame(width: 90, height: 18)
                        }
                    }
                    Spacer()
                }
                .padding(16)

                // 좌하단 시청자 수 영역
                VStack {
                    Spacer()
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray45.opacity(0.7))
                            .frame(width: 100, height: 24)

                        Spacer()
                    }
                }
                .padding(16)

                // 우하단 면적 영역
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray45)
                            .frame(width: 80, height: 12)
                    }
                }
                .padding(16)
            }
        }
        .aspectRatio(2.5, contentMode: .fit)
    }
}

// MARK: - Topic Row Skeleton

struct TopicRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(width: 200, height: 18)
                .skeleton()

            // 내용
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(height: 14)
                .skeleton()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(width: UIScreen.main.bounds.width * 0.6, height: 14)
                .skeleton()

            // 날짜
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(width: 80, height: 12)
                .skeleton()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray15)
        .cornerRadius(8)
    }
}

// MARK: - Hero Banner Skeleton

struct HeroBannerSkeleton: View {
    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    var body: some View {
        ZStack {
            // 배경
            Rectangle()
                .fill(Color.gray30)
                .skeleton()

            // 검색바 영역 (상단)
            VStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray0.opacity(0.9))
                    .frame(height: 48)
                    .padding(.horizontal, 16)
                    .padding(.top, topSafeAreaInset + 8)

                Spacer()
            }

            // 텍스트 영역 (하단)
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    // 위치
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray0.opacity(0.7))
                        .frame(width: 80, height: 14)

                    // 제목
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray0.opacity(0.7))
                        .frame(width: 200, height: 24)

                    // 설명
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray0.opacity(0.5))
                        .frame(width: 150, height: 14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            // 페이지 인디케이터 (하단 중앙)
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray60.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .frame(height: 335)
    }
}

// MARK: - Preview

#Preview("Estate Card Skeletons") {
    ScrollView {
        VStack(spacing: 24) {
            // Small Card
            Text("Small Card Skeleton")
                .font(.headline)
            EstateCardSmallSkeleton()
                .padding(.horizontal, 16)

            // Large Card
            Text("Large Card Skeleton")
                .font(.headline)
            EstateCardLargeSkeleton()
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .padding(.horizontal, 16)

            // Topic Row
            Text("Topic Row Skeleton")
                .font(.headline)
            TopicRowSkeleton()
                .padding(.horizontal, 16)

            // Hero Banner
            Text("Hero Banner Skeleton")
                .font(.headline)
            HeroBannerSkeleton()
        }
        .padding(.vertical)
    }
    .background(Color.gray0)
}
