import SwiftUI

// MARK: - Estate Card Small Skeleton (오늘의 매물용)

struct EstateCardSmallSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일 영역
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray30)
                .frame(width: 69, height: 69)
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
        .background(Color.gray0)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray30, lineWidth: 1)
        )
    }
}

// MARK: - Estate Card Large Skeleton (HOT 매물용)

struct EstateCardLargeSkeleton: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 배경
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray30)
                .skeleton()

            // 좌상단 HOT 아이콘 영역
            VStack {
                HStack {
                    Circle()
                        .fill(Color.gray45)
                        .frame(width: 20, height: 20)

                    Spacer()
                }
                Spacer()
            }
            .padding(8)

            // 우상단 텍스트 영역
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        // 제목
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray45)
                            .frame(width: 110, height: 12)

                        // 가격
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray45)
                            .frame(width: 80, height: 14)
                    }
                }
                Spacer()
            }
            .padding(10)

            // 좌하단 시청자 수 영역
            VStack {
                Spacer()
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray45.opacity(0.7))
                        .frame(width: 90, height: 18)

                    Spacer()
                }
            }
            .padding(10)

            // 우하단 면적 영역
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray45)
                        .frame(width: 60, height: 10)
                }
            }
            .padding(10)
        }
        .frame(width: 240, height: 83)
    }
}

// MARK: - Topic Row Skeleton

struct TopicRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 200, height: 16)
                    .skeleton()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 220, height: 12)
                    .skeleton()
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(width: 50, height: 10)
                .skeleton()
        }
        .frame(height: 76)
    }
}

// MARK: - Hero Banner Skeleton

struct HeroBannerSkeleton: View {
    let height: CGFloat

    var body: some View {
        ZStack {
            // 배경
            Rectangle()
                .fill(Color.gray30)
                .skeleton()

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
        .frame(height: height)
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
                .frame(width: 240, height: 83)
                .padding(.horizontal, 16)

            // Topic Row
            Text("Topic Row Skeleton")
                .font(.headline)
            TopicRowSkeleton()
                .padding(.horizontal, 16)

            // Hero Banner
            Text("Hero Banner Skeleton")
                .font(.headline)
            HeroBannerSkeleton(height: 355)
        }
        .padding(.vertical)
    }
    .background(Color.gray0)
}
