import SwiftUI

struct MapFilterControlsView: View {
    @Binding var filterState: MapFilterState
    let viewState: MapViewState
    let onToggleFilter: (MapViewState.FilterType) -> Void
    let onApplyFilter: (MapViewState.FilterType) -> Void
    let onResetFilters: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !isFilterAdjusting {
                filterButtonGroup
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            if case .filterAdjusting(let type) = viewState {
                filterPanel(for: type)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var isFilterAdjusting: Bool {
        if case .filterAdjusting = viewState { return true }
        return false
    }

    private var filterButtonGroup: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapViewState.FilterType.allCases, id: \.self) { type in
                    FilterChipButton(title: type.title, isActive: filterState.isActive(type)) {
                        onToggleFilter(type)
                    }
                }

                if filterState.hasActiveFilters {
                    Button(action: onResetFilters) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("초기화")
                                .font(.pretendardCaption1)
                        }
                        .foregroundColor(.gray75)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray15)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func filterPanel(for type: MapViewState.FilterType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(type.panelTitle)
                    .font(.pretendardBody2Bold)
                    .foregroundColor(.gray90)

                Spacer()

                Button("적용") {
                    onApplyFilter(type)
                }
                .font(.pretendardCaption1)
                .foregroundColor(.deepWood)
            }

            Text(filterState.rangeText(type))
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            rangeSlider(for: type)
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func rangeSlider(for type: MapViewState.FilterType) -> some View {
        RangeSliderView(
            lowerValue: lowerBinding(for: type),
            upperValue: upperBinding(for: type),
            bounds: MapFilterState.bounds(type)
        )
    }

    private func lowerBinding(for type: MapViewState.FilterType) -> Binding<Double> {
        Binding(
            get: { range(for: type).lowerBound },
            set: { lower in
                let upper = range(for: type).upperBound
                setRange(lower...upper, for: type)
            }
        )
    }

    private func upperBinding(for type: MapViewState.FilterType) -> Binding<Double> {
        Binding(
            get: { range(for: type).upperBound },
            set: { upper in
                let lower = range(for: type).lowerBound
                setRange(lower...upper, for: type)
            }
        )
    }

    private func range(for type: MapViewState.FilterType) -> ClosedRange<Double> {
        switch type {
        case .deposit: return filterState.depositRange
        case .monthlyRent: return filterState.monthlyRentRange
        case .area: return filterState.areaRange
        }
    }

    private func setRange(_ range: ClosedRange<Double>, for type: MapViewState.FilterType) {
        switch type {
        case .deposit: filterState.depositRange = range
        case .monthlyRent: filterState.monthlyRentRange = range
        case .area: filterState.areaRange = range
        }
    }
}
