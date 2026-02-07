import SwiftUI

struct RangeSliderView: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let range = bounds.upperBound - bounds.lowerBound
            let lowerX = CGFloat((lowerValue - bounds.lowerBound) / range) * width
            let upperX = CGFloat((upperValue - bounds.lowerBound) / range) * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray30)
                    .frame(height: 4)

                Capsule()
                    .fill(Color.deepWood)
                    .frame(width: max(upperX - lowerX, 0), height: 4)
                    .offset(x: lowerX)

                sliderThumb
                    .position(x: lowerX, y: 10)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = min(max(0, value.location.x), upperX - 20)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            lowerValue = min(max(bounds.lowerBound, newValue), upperValue)
                        }
                    )

                sliderThumb
                    .position(x: upperX, y: 10)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = max(min(width, value.location.x), lowerX + 20)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            upperValue = max(min(bounds.upperBound, newValue), lowerValue)
                        }
                    )
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }

    private var sliderThumb: some View {
        Circle()
            .stroke(Color.deepWood, lineWidth: 2)
            .background(Circle().fill(Color.gray0))
            .frame(width: 20, height: 20)
    }
}
