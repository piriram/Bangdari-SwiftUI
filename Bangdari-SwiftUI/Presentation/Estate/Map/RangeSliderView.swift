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

            ZStack(alignment: .topLeading) {
                // 카드 배경(단일)
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .fill(Color.gray0)
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 3)

                // 트랙(비활성)
                trackBackground(width: sliderWidth)
                    .position(x: Layout.horizontalPadding + sliderWidth / 2, y: Layout.trackCenterY)

                // 활성 구간(단색)
                activeTrack(lowerX: lowerX, upperX: upperX, y: Layout.trackCenterY)

                // 틱(눈금)
                tickMarks(width: sliderWidth, y: Layout.trackCenterY)

                // 썸(좌)
                thumb(strokeColor: .brightWood)
                    .position(x: lowerX, y: Layout.trackCenterY)
                    .gesture(dragGesture(isLowerThumb: true, sliderWidth: sliderWidth, valueRange: range))

                // 썸(우)
                thumb(strokeColor: Color.gray90.opacity(0.95))
                    .position(x: upperX, y: Layout.trackCenterY)
                    .gesture(dragGesture(isLowerThumb: false, sliderWidth: sliderWidth, valueRange: range))

                // 툴팁(상단)
                tooltip(text: selectedRangeText)
                    .position(
                        x: tooltipX(lowerX: lowerX, upperX: upperX, width: sliderWidth),
                        y: Layout.tooltipCenterY
                    )

                // 스케일 라벨(하단)
                scaleLabels(width: sliderWidth)
                    .position(
                        x: Layout.horizontalPadding + sliderWidth / 2,
                        y: Layout.labelsCenterY
                    )
            }
            .padding(.horizontal, 0) // GeometryReader 내부에서 직접 패딩 계산하므로 0
        }
        .frame(height: Layout.totalHeight)
    }

    // MARK: - UI Pieces

    private func trackBackground(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.gray30)
            .frame(width: width, height: Layout.trackHeight)
    }

    private func activeTrack(lowerX: CGFloat, upperX: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(Color.brightWood) // 이미지처럼 단색
            .frame(width: max(upperX - lowerX, 0), height: Layout.trackHeight)
            .position(x: lowerX + max(upperX - lowerX, 0) / 2, y: y)
    }

    private func tickMarks(width: CGFloat, y: CGFloat) -> some View {
        ZStack {
            ForEach(scaleDefinitions.indices, id: \.self) { index in
                let position = scaleDefinitions[index].position
                Rectangle()
                    .fill(Color.gray60)
                    .frame(width: 1, height: Layout.tickHeight)
                    .position(x: Layout.horizontalPadding + (width * position), y: y)
            }
        }
    }

    private func thumb(strokeColor: Color) -> some View {
        Circle()
            .fill(Color.gray0)
            .overlay(
                Circle().stroke(strokeColor, lineWidth: 2)
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
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray60, lineWidth: 1)
                        )
                )
        }
    }

    private func scaleLabels(width: CGFloat) -> some View {
        ZStack {
            ForEach(scaleDefinitions.indices, id: \.self) { index in
                let def = scaleDefinitions[index]
                let x = Layout.horizontalPadding + (width * def.position)

                Text(def.title)
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .position(x: x, y: 7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 14)
    }

    private func tooltipX(lowerX: CGFloat, upperX: CGFloat, width: CGFloat) -> CGFloat {
        let desired = (lowerX + upperX) / 2
        let minX = Layout.horizontalPadding + Layout.tooltipHorizontalInset
        let maxX = Layout.horizontalPadding + width - Layout.tooltipHorizontalInset
        return min(max(desired, minX), maxX)
    }

    // MARK: - Drag

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
                    if lowerDragStartValue == nil { lowerDragStartValue = lowerValue }
                    guard let start = lowerDragStartValue else { return }
                    let candidate = start + deltaValue
                    lowerValue = min(max(bounds.lowerBound, candidate), upperValue - minimumGap)
                } else {
                    if upperDragStartValue == nil { upperDragStartValue = upperValue }
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

    // MARK: - Text / Scale

    private var selectedRangeText: String {
        if isCurrencyScale {
            return "\(formatCurrency(lowerValue)) ~ \(formatCurrency(upperValue))" // 이미지처럼 물결 표기
        }
        return "\(Int(lowerValue)) ~ \(Int(upperValue))"
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

    private var isCurrencyScale: Bool { bounds.upperBound >= 1_000_000 }

    private func formatCurrency(_ value: Double) -> String {
        PriceFormatter.format(value, includeUnit: false)
    }
}

// MARK: - Layout

private enum Layout {
    static let totalHeight: CGFloat = 86          // 카드 높이(이미지에 더 근접)
    static let horizontalPadding: CGFloat = 40

    static let tooltipCenterY: CGFloat = 18       // 툴팁 위쪽
    static let trackCenterY: CGFloat = 42         // 트랙 중앙
    static let labelsCenterY: CGFloat = 70        // 라벨 아래

    static let tooltipHorizontalInset: CGFloat = 42

    static let cardCornerRadius: CGFloat = 16

    static let trackHeight: CGFloat = 6
    static let tickHeight: CGFloat = 8

    static let thumbSize: CGFloat = 18
    static let minimumThumbDistance: CGFloat = 20
}

// MARK: - Pointer

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
