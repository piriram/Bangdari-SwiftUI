import Kingfisher
import SwiftUI

struct MapEstateCardCarouselView: View {
    let estates: [EstateSummaryResponse]
    @Binding var selectedEstateIndex: Int
    let onCardTap: (EstateSummaryResponse) -> Void
    let onSwipeNext: () -> Void
    let onSwipePrevious: () -> Void
    let onSelectionChanged: (EstateSummaryResponse) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(estates.enumerated()), id: \.element.estate_id) { index, estate in
                        MapEstateCardView(estate: estate)
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .id(index)
                            .onTapGesture {
                                onCardTap(estate)
                            }
                    }
                }
                .padding(.horizontal, 16)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 160)
            .onChange(of: selectedEstateIndex) { _, newIndex in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }

                if let estate = estates[safe: newIndex] {
                    onSelectionChanged(estate)
                }
            }
            .gesture(
                DragGesture().onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        onSwipeNext()
                    } else if value.translation.width > threshold {
                        onSwipePrevious()
                    }
                }
            )
            .padding(.bottom, 24)
        }
    }
}

private struct MapEstateCardView: View {
    let estate: EstateSummaryResponse

    var body: some View {
        HStack(spacing: 12) {
            KFImage.auth(url: estate.mapImageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(estate.category)
                    .font(.pretendardCaption1)
                    .foregroundColor(.deepWood)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brightCream)
                    .cornerRadius(8)

                Text(estate.title)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                Text(estate.mapCardPriceText)
                    .font(.pretendardTitle1)
                    .foregroundColor(.gray90)

                HStack(spacing: 8) {
                    Text(estate.formattedArea())
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray75)

                    Text("·")
                        .foregroundColor(.gray60)

                    Text("영등포구") // TODO: 실제 주소
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray60)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
