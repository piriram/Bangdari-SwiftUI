import Kingfisher
import SwiftUI

// MARK: - Inline Promo Item

struct InlinePromoItem: View {
    let banner: Banner
    let onTap: (String) -> Void

    var body: some View {
        Button {
            if let url = banner.actionUrl {
                onTap(url)
            }
        } label: {
            KFImage.auth(url: imageURL)
                .placeholder {
                    ZStack {
                        Color.gray30
                        HStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(.gray60)

                            Text(banner.title)
                                .font(.pretendardCaption1)
                                .foregroundColor(.gray75)
                        }
                    }
                }
                .onFailure { error in
                    print("❌ [BANNER-IMG] 로딩 실패")
                    print("  - Banner: \(banner.title)")
//                    print("  - URL: \(imageURL?.absoluteString ?? \"nil\")")
                    print("  - Error: \(error.localizedDescription)")
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 66)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var imageURL: URL? {
        guard !banner.image.isEmpty else {
            print("⚠️ [BANNER-UI] 이미지 경로가 비어있음")
            return nil
        }

        return MockImageMapper.resolvedImageURL(from: banner.image)
    }
}
