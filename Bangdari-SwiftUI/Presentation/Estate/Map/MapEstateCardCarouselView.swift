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
    @State private var address: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            textStack
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(Color.gray0)
        .cornerRadius(16)
        .task {
            GeolocationManager.shared.fetchFullAddress(
                latitude: estate.geolocation.latitude,
                longitude: estate.geolocation.longitude
            ) { fetchedAddress in
                address = fetchedAddress
            }
        }
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            KFImage.auth(url: estate.mapImageURL)
                .placeholder {
                    Color.gray30
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(10)

            if estate.is_safe_estate {
                DSIconView(.safety, size: 20, renderingMode: .original)
                    .offset(x: 8, y: 8)
            }
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                tagBadge

                Text(estate.formattedPrice())
                    .font(.pretendard(.body1, .bold))
                    .foregroundColor(.gray90)
                    .lineLimit(1)
            }

            Text(estate.title)
                .font(.pretendard(.caption1, .semiBold))
                .foregroundColor(.gray75)
                .lineLimit(2)

            Text("\(estate.formattedArea()) · \(estate.floors)층")
                .font(.pretendard(.caption1))
                .foregroundColor(.gray75)

            if !estate.introduction.isEmpty {
                Text("◇ \(estate.introduction)")
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagBadge: some View {
        Text(estate.category)
            .font(.pretendardCaption1)
            .foregroundColor(.deepWood)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.gray0)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.deepWood, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
