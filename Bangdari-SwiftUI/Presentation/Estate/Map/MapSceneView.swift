import MapKit
import SwiftUI

struct MapSceneView: View {
    @Binding var position: MapCameraPosition
    let clusters: [MapCluster]
    let skeletonClusters: [SkeletonCluster]
    let regionSpan: Double
    let selectedEstate: EstateSummaryResponse?
    let onClusterTap: (MapCluster) -> Void
    let onMapCameraChange: (MKCoordinateRegion) -> Void
    let onMapTap: () -> Void

    var body: some View {
        Map(position: $position) {
            ForEach(clusters) { cluster in
                Annotation(
                    cluster.isSingle ? (cluster.firstEstate?.title ?? "") : "\(cluster.count)개",
                    coordinate: cluster.coordinate
                ) {
                    clusterMarker(cluster)
                }
            }

            ForEach(skeletonClusters) { skeleton in
                Annotation("", coordinate: skeleton.coordinate) {
                    MapSkeletonMarkerView()
                }
            }

            UserAnnotation()
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            onMapCameraChange(context.region)
        }
        .onTapGesture {
            onMapTap()
        }
    }

    private func clusterMarker(_ cluster: MapCluster) -> some View {
        Button {
            onClusterTap(cluster)
        } label: {
            if cluster.isSingle,
               regionSpan < MapConstants.markerBalloonThreshold,
               let estate = cluster.firstEstate {
                EstateMarkerView(
                    estate: estate,
                    isSelected: selectedEstate?.estate_id == estate.estate_id
                )
            } else {
                MapClusterBubbleView(count: cluster.count)
            }
        }
        .buttonStyle(.plain)
    }
}
