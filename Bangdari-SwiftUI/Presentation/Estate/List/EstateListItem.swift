import Kingfisher
import SwiftUI

// MARK: - Estate List Item

struct EstateListItem: View {
    let estate: EstateSummaryResponse

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            textStack
        }
        .padding(12)
        .frame(height: 140)
        .background(Color.gray0)
        .cornerRadius(20)
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            KFImage.auth(url: estate.mapImageURL)
                .placeholder {
                    Color.gray30
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 108)
                .clipped()
                .cornerRadius(12)

            Circle()
                .fill(Color.deepCoast)
                .frame(width: 20, height: 20)
                .overlay {
                    Image(dsIcon: .focus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.gray0)
                }
                .offset(x: 8, y: 8)

            if estate.is_safe_estate {
                Circle()
                    .fill(Color.brightWood)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(dsIcon: .safety)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(.gray0)
                    }
                    .offset(x: 112, y: 8)
            }
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            tagBadge

            Text(estate.title)
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)
                .lineLimit(1)

            Text(estate.formattedPrice())
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            Text("\(estate.formattedArea()) · \(estate.floors)층")
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)

            if let distance = estate.distance {
                Text(distanceText(distance))
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagBadge: some View {
        Text(estate.category)
            .font(.pretendardCaption1)
            .foregroundColor(.gray75)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.gray0)
            .overlay(
                Capsule()
                    .stroke(Color.gray45, lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000)
        }

        return "\(Int(meters))m"
    }
}
