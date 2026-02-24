import Kingfisher
import SwiftUI

// MARK: - Post Card (커뮤니티용 Waterfall 카드)

/// 커뮤니티 게시글 카드 컴포넌트
/// - Waterfall 레이아웃에 최적화 (동적 높이)
/// - 이미지 있으면 썸네일 강조, 없으면 텍스트 미리보기
struct PostCard: View {
    let post: PostSummaryResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 썸네일 (있는 경우)
            if let firstFile = post.files.first,
               let imageURL = MockImageMapper.resolvedImageURL(from: firstFile) {
                KFImage.auth(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: calculateImageHeight())
                    .clipped()
                    .background(Color.gray30)
            }

            // 카드 내용
            VStack(alignment: .leading, spacing: 8) {
                // 카테고리 뱃지
                Text(post.category)
                    .font(.pretendardCaption2)
                    .foregroundColor(.brightWood)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brightWood.opacity(0.1))
                    .cornerRadius(4)

                // 제목
                Text(post.title)
                    .font(.pretendardBody2Bold)
                    .foregroundColor(.gray90)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 내용 미리보기 (이미지 없을 때만)
                if post.files.isEmpty {
                    Text(post.content)
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray75)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                // 하단 정보
                HStack(spacing: 8) {
                    // 작성자
                    Text(post.creator.nick)
                        .font(.pretendardCaption2)
                        .foregroundColor(.gray60)

                    Spacer()

                    // 좋아요
                    HStack(spacing: 4) {
                        Image(systemName: post.is_like ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(post.is_like ? .red : .gray60)

                        Text("\(post.like_count)")
                            .font(.pretendardCaption2)
                            .foregroundColor(.gray60)
                    }
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color.gray0)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    /// 이미지 높이 계산 (랜덤하게 보이도록)
    /// - Returns: 계산된 높이
    private func calculateImageHeight() -> CGFloat {
        // 이미지가 있으면 해시값 기반으로 높이 결정 (일관성 유지)
        let seed = abs(post.post_id.hashValue)
        let heights: [CGFloat] = [120, 150, 180, 200]
        return heights[seed % heights.count]
    }
}
