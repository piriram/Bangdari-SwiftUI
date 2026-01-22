import Kingfisher
import SwiftUI

// MARK: - Estate Card Large (HOT 매물용)

struct EstateCardLarge: View {
    let estate: EstateSummaryResponse
    var viewerCount: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 배경 이미지
                KFImage.auth(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // 그라데이션 오버레이
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 콘텐츠
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    // 제목
                    Text(estate.title)
                        .font(.pretendardTitle1)
                        .foregroundColor(.gray0)
                        .lineLimit(2)

                    // 가격
                    Text(priceText)
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray0)

                    // 실시간 정보
                    if let count = viewerCount, count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                            Text("\(count)명이 함께 보는 중")
                                .font(.pretendardCaption1)
                        }
                        .foregroundColor(.gray0.opacity(0.8))
                    }
                }
                .padding(16)

                // HOT 배지
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                            Text("HOT")
                                .font(.pretendardCaption1)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.gray0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.deepWood)
                        .cornerRadius(16)

                        Spacer()
                    }
                    .padding(12)

                    Spacer()
                }
            }
            .cornerRadius(16)
        }
        .aspectRatio(16 / 10, contentMode: .fit)
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private var priceText: String {
        if estate.monthly_rent > 0 {
            return "월세 \(formatPrice(estate.deposit))/\(estate.monthly_rent)"
        } else {
            return "전세 \(formatPrice(estate.deposit))"
        }
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let uk = price / 10000
            let remain = price % 10000
            if remain == 0 {
                return "\(uk)억"
            } else {
                return "\(uk)억 \(remain)"
            }
        }
        return "\(price)"
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            EstateCardLarge(estate: .preview, viewerCount: 34)
                .frame(width: 300)

            EstateCardLarge(estate: .preview)
                .frame(width: 300)
        }
        .padding(.horizontal, 16)
    }
}
