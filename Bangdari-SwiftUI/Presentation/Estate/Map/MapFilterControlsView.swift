import SwiftUI

struct MapFilterControlsView: View {
    @Binding var filterState: MapFilterState
    let viewState: MapViewState
    let onToggleFilter: (MapViewState.FilterType) -> Void
    let onRangeChangedDebounced: (MapViewState.FilterType) -> Void
    let onResetFilters: () -> Void
    @State private var debounceTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            filterButtonGroup
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            if case .filterAdjusting(let type) = viewState {
                adjustingRangeControl(for: type)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: viewState) { _, newState in
            if case .filterAdjusting = newState {
                return
            }
            debounceTask?.cancel()
        }
        .onDisappear {
            debounceTask?.cancel()
        }
    }
    
    private var filterButtonGroup: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapViewState.FilterType.allCases, id: \.self) { type in
                    FilterChipButton(
                        title: type.title,
                        isActive: selectedAdjustingType == type,
                        style: .filledActive
                    ) {
                        onToggleFilter(type)
                    }
                }
                
                if filterState.hasActiveFilters {
                    Button(action: onResetFilters) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
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
    
    private var selectedAdjustingType: MapViewState.FilterType? {
        if case .filterAdjusting(let type) = viewState {
            return type
        }
        return nil
    }
    
    private func adjustingRangeControl(for type: MapViewState.FilterType) -> some View {
        rangeSlider(for: type)
    }
    
    @ViewBuilder
    private func rangeSlider(for type: MapViewState.FilterType) -> some View {
        switch type {
        case .deposit:
            RangeSliderView(
                lowerValue: lowerBinding(for: type),
                upperValue: upperBinding(for: type),
                bounds: MapFilterState.bounds(type)
            )
            .onChange(of: filterState.depositRange) { _ in
                notifyRangeChangedDebounced(type)
            }
        case .monthlyRent:
            RangeSliderView(
                lowerValue: lowerBinding(for: type),
                upperValue: upperBinding(for: type),
                bounds: MapFilterState.bounds(type)
            )
            .onChange(of: filterState.monthlyRentRange) { _ in
                notifyRangeChangedDebounced(type)
            }
        case .area:
            RangeSliderView(
                lowerValue: lowerBinding(for: type),
                upperValue: upperBinding(for: type),
                bounds: MapFilterState.bounds(type)
            )
            .onChange(of: filterState.areaRange) { _ in
                notifyRangeChangedDebounced(type)
            }
        }
    }
    
    private func notifyRangeChangedDebounced(_ type: MapViewState.FilterType) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            onRangeChangedDebounced(type)
        }
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
