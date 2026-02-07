import SwiftUI

struct MapClusterBubbleView: View {
    let count: Int

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
    }

    private var clusterSize: CGFloat {
        if count >= 200 { return 120 }
        if count >= 100 { return 90 }
        if count >= 50 { return 70 }
        if count >= 20 { return 56 }
        if count >= 10 { return 48 }
        return 40
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
