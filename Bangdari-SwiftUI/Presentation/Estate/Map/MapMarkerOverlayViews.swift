import SwiftUI

struct MapClusterBubbleView: View {
    let count: Int
    let regionSpan: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.deepCream.opacity(0.3))
                .frame(width: clusterSize + 12, height: clusterSize + 12)

            Circle()
                .fill(Color.deepCream.opacity(0.75))
                .frame(width: clusterSize, height: clusterSize)

            Text("\(count)")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray0)
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: count)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: regionSpan)
    }

    private var clusterSize: CGFloat {
        let baseSize: CGFloat
        if count >= 200 {
            baseSize = 120
        } else if count >= 100 {
            baseSize = 90
        } else if count >= 50 {
            baseSize = 70
        } else if count >= 20 {
            baseSize = 56
        } else if count >= 10 {
            baseSize = 48
        } else {
            baseSize = 40
        }

        return baseSize * zoomOutScale
    }

    private var zoomOutScale: CGFloat {
        switch regionSpan {
        case 0.5...:
            return 1.7
        case 0.1..<0.5:
            return 1.45
        case 0.05..<0.1:
            return 1.3
        case 0.02..<0.05:
            return 1.15
        default:
            return 1.0
        }
    }
}

struct MapSkeletonMarkerView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray30.opacity(0.5))
                .frame(width: 44, height: 44)

            ProgressView()
                .tint(.gray60)
                .scaleEffect(0.8)
        }
    }
}
