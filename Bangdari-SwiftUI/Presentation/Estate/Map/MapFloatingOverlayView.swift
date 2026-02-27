import SwiftUI

struct MapFloatingOverlayView: View {
    @Binding var filterState: MapFilterState
    let viewState: MapViewState
    let onToggleFilter: (MapViewState.FilterType) -> Void
    let onRangeChangedDebounced: (MapViewState.FilterType) -> Void
    let onResetFilters: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onCurrentLocation: () -> Void
    let estates: [EstateSummaryResponse]
    @Binding var selectedEstateIndex: Int
    let onCardTap: (EstateSummaryResponse) -> Void
    let onSwipeNext: () -> Void
    let onSwipePrevious: () -> Void
    let onSelectionChanged: (EstateSummaryResponse) -> Void
    
    private var shouldShowCarousel: Bool {
        !estates.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            MapFilterControlsView(
                filterState: $filterState,
                viewState: viewState,
                onToggleFilter: onToggleFilter,
                onRangeChangedDebounced: onRangeChangedDebounced,
                onResetFilters: onResetFilters
            )

            Spacer()

            HStack {
                Spacer()
                MapControlButtonsView(
                    onZoomIn: onZoomIn,
                    onZoomOut: onZoomOut,
                    onCurrentLocation: onCurrentLocation
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, shouldShowCarousel ? 8 : 24)

            if shouldShowCarousel {
                MapEstateCardCarouselView(
                    estates: estates,
                    selectedEstateIndex: $selectedEstateIndex,
                    onCardTap: onCardTap,
                    onSwipeNext: onSwipeNext,
                    onSwipePrevious: onSwipePrevious,
                    onSelectionChanged: onSelectionChanged
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewState)
    }
}
