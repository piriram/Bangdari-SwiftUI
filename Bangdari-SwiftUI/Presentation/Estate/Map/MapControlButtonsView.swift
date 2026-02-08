import SwiftUI

struct MapControlButtonsView: View {
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onCurrentLocation: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            zoomControls
            currentLocationButton
        }
    }

    private var zoomControls: some View {
        VStack(spacing: 0) {
            Button(action: onZoomIn) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray90)
                    .frame(width: 44, height: 44)
            }

            Divider()
                .frame(width: 24)

            Button(action: onZoomOut) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray90)
                    .frame(width: 44, height: 44)
            }
        }
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var currentLocationButton: some View {
        Button(action: onCurrentLocation) {
            DSIconView(.focus, size: 24, renderingMode: .template)
                .foregroundColor(.gray75)
                .frame(width: 40, height: 40)
                .background(Color.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
}
