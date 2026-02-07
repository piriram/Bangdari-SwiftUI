import SwiftUI

struct RangeSliderView: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>
    @State private var lowerDragStartValue: Double?
    @State private var upperDragStartValue: Double?

    var body: some View {
        GeometryReader { proxy in
            let sliderWidth = max(proxy.size.width - (Layout.horizontalPadding * 2), 1)
            let range = max(bounds.upperBound - bounds.lowerBound, 1)

            let lowerRatio = CGFloat((lowerValue - bounds.lowerBound) / range)
            let upperRatio = CGFloat((upperValue - bounds.lowerBound) / range)

            let lowerX = Layout.horizontalPadding + (sliderWidth * lowerRatio)
            let upperX = Layout.horizontalPadding + (sliderWidth * upperRatio)
            let trackY = Layout.pointerHeight + Layout.topContentInset + (Layout.trackHeight / 2)

            ZStack(alignment: .topLeading) {
                cardBackground

                trackBackground(width: sliderWidth)
                    .position(x: Layout.horizontalPadding + sliderWidth / 2, y: trackY)

                activeTrack(lowerX: lowerX, upperX: upperX, y: trackY)

                tickMarks(width: sliderWidth, y: trackY - 11)

                thumb(strokeColor: .brightWood)
                    .position(x: lowerX, y: trackY)
                    .gesture(
                        dragGesture(
                            isLowerThumb: true,
                            sliderWidth: sliderWidth,
                            valueRange: range
                        )
                    )

                thumb(strokeColor: Color.gray90.opacity(0.95))
                    .position(x: upperX, y: trackY)
                    .gesture(
                        dragGesture(
                            isLowerThumb: false,
                            sliderWidth: sliderWidth,
                            valueRange: range
                        )
                    )

                tooltip(text: selectedRangeText)
                    .position(
                        x: tooltipX(lowerX: lowerX, upperX: upperX, width: sliderWidth),
                        y: trackY - 25
                    )

                scaleLabels(width: sliderWidth)
                    .position(
                        x: Layout.horizontalPadding + sliderWidth / 2,
                        y: trackY + 24
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: Layout.totalHeight)
    }

    private var cardBackground: some View {
        VStack(spacing: 0) {
            TopPointer()
                .fill(Color.gray0)
                .frame(width: 16, height: Layout.pointerHeight)
                .frame(maxWidth: .infinity)

            RoundedRectangle(cornerRadius: 22)
                .fill(Color.gray0)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func trackBackground(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.gray30)
            .frame(width: width, height: Layout.trackHeight)
    }

    private func activeTrack(lowerX: CGFloat, upperX: CGFloat, y: CGFloat) -> some View {
        LinearGradient(
            colors: [Color.brightWood, Color.deepWood, Color.gray100.opacity(0.9)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .clipShape(Capsule())
        .frame(width: max(upperX - lowerX, 0), height: Layout.trackHeight)
        .position(x: lowerX + max(upperX - lowerX, 0) / 2, y: y)
    }

    private func tickMarks(width: CGFloat, y: CGFloat) -> some View {
        ZStack {
            ForEach(scaleDefinitions.indices, id: \.self) { index in
                let position = scaleDefinitions[index].position
                Rectangle()
                    .fill(Color.gray45.opacity(0.45))
                    .frame(width: 1, height: 8)
                    .position(x: Layout.horizontalPadding + (width * position), y: y)
            }
        }
    }

    private func thumb(strokeColor: Color) -> some View {
        Circle()
            .fill(Color.gray0)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: 2)
            )
            .frame(width: Layout.thumbSize, height: Layout.thumbSize)
            .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
    }

    private func tooltip(text: String) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.pretendardCaption1)
                .foregroundColor(.gray75)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray45, lineWidth: 1)
                        )
                )

            BottomPointer()
                .fill(Color.gray0)
                .frame(width: 10, height: 6)
                .overlay(
                    BottomPointer()
                        .stroke(Color.gray45, lineWidth: 1)
                )
                .offset(y: -1)
        }
    }

    private func scaleLabels(width: CGFloat) -> some View {
        ZStack {
            ForEach(scaleDefinitions.indices, id: \.self) { index in
                let definition = scaleDefinitions[index]
                let x = min(max(width * definition.position, 16), width - 16)
                Text(definition.title)
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .position(x: x, y: 8)
            }
        }
        .frame(width: width, height: 16)
    }

    private func tooltipX(lowerX: CGFloat, upperX: CGFloat, width: CGFloat) -> CGFloat {
        let desired = (lowerX + upperX) / 2
        let minX = Layout.horizontalPadding + 42
        let maxX = Layout.horizontalPadding + width - 42
        return min(max(desired, minX), maxX)
    }

    private func dragGesture(
        isLowerThumb: Bool,
        sliderWidth: CGFloat,
        valueRange: Double
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let minimumGap = valueRange * Double(Layout.minimumThumbDistance / sliderWidth)
                let deltaValue = Double(value.translation.width / sliderWidth) * valueRange

                if isLowerThumb {
                    if lowerDragStartValue == nil {
                        lowerDragStartValue = lowerValue
                    }

                    guard let start = lowerDragStartValue else { return }
                    let candidate = start + deltaValue
                    lowerValue = min(max(bounds.lowerBound, candidate), upperValue - minimumGap)
                } else {
                    if upperDragStartValue == nil {
                        upperDragStartValue = upperValue
                    }

                    guard let start = upperDragStartValue else { return }
                    let candidate = start + deltaValue
                    upperValue = max(min(bounds.upperBound, candidate), lowerValue + minimumGap)
                }
            }
            .onEnded { _ in
                lowerDragStartValue = nil
                upperDragStartValue = nil
            }
    }

    private var selectedRangeText: String {
        if isCurrencyScale {
            return "\(formatCurrency(lowerValue)) - \(formatCurrency(upperValue))"
        }

        return "\(Int(lowerValue)) - \(Int(upperValue))"
    }

    private var scaleDefinitions: [(position: CGFloat, title: String)] {
        if bounds.upperBound >= 100_000_000 {
            return [
                (0.0, "최소"),
                (0.5, "5천만"),
                (0.75, "1억"),
                (1.0, "최대")
            ]
        }

        if isCurrencyScale {
            let first = bounds.upperBound / 3
            let second = (bounds.upperBound * 2) / 3
            return [
                (0.0, "최소"),
                (1.0 / 3.0, formatCurrency(first)),
                (2.0 / 3.0, formatCurrency(second)),
                (1.0, "최대")
            ]
        }

        return [
            (0.0, "최소"),
            (1.0 / 3.0, "\(Int(bounds.upperBound / 3))"),
            (2.0 / 3.0, "\(Int((bounds.upperBound * 2) / 3))"),
            (1.0, "최대")
        ]
    }

    private var isCurrencyScale: Bool {
        bounds.upperBound >= 1_000_000
    }

    private func formatCurrency(_ value: Double) -> String {
        PriceFormatter.format(value, includeUnit: false)
    }
}

private enum Layout {
    static let totalHeight: CGFloat = 84
    static let pointerHeight: CGFloat = 8
    static let horizontalPadding: CGFloat = 18
    static let topContentInset: CGFloat = 26
    static let trackHeight: CGFloat = 6
    static let thumbSize: CGFloat = 20
    static let minimumThumbDistance: CGFloat = 22
}

private struct TopPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct BottomPointer: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let minX = rect.minX + insetAmount
        let maxX = rect.maxX - insetAmount
        let maxY = rect.maxY - insetAmount
        let minY = rect.minY + insetAmount

        path.move(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: rect.midX, y: maxY))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
