import SwiftUI

// MARK: - Post Card Skeleton

struct PostCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 카테고리 + 작성자
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 60, height: 20)
                    .skeleton()

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 50, height: 16)
                    .skeleton()
            }

            // 제목
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray30)
                .frame(height: 20)
                .skeleton()

            // 내용 (2줄)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(height: 16)
                    .skeleton()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray30)
                    .frame(width: 200, height: 16)
                    .skeleton()
            }

            // 하단 정보
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray30)
                    .frame(width: 60, height: 60)
                    .skeleton()

                Spacer()

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray30)
                        .frame(width: 40, height: 16)
                        .skeleton()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray30)
                        .frame(width: 70, height: 16)
                        .skeleton()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Post List Skeleton

struct PostListSkeleton: View {
    var body: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                PostCardSkeleton()
            }
        }
        .listStyle(.plain)
        .disabled(true)
    }
}

// MARK: - Preview

#Preview("Post Skeletons") {
    VStack(spacing: 24) {
        Text("Post Card Skeleton")
            .font(.headline)
        PostCardSkeleton()
            .padding(.horizontal, 16)

        Text("Post List Skeleton")
            .font(.headline)
        PostListSkeleton()
    }
    .background(Color.gray0)
}
