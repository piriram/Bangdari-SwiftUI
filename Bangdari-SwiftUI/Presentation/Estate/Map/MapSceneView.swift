import MapKit
import SwiftUI

private final class EstateAnnotation: NSObject, MKAnnotation {
    let estate: EstateSummaryResponse
    dynamic var coordinate: CLLocationCoordinate2D

    init(estate: EstateSummaryResponse) {
        self.estate = estate
        self.coordinate = estate.geolocation.coordinate
        super.init()
    }
}

struct MapSceneView: UIViewRepresentable {
    @Binding var position: MapCameraPosition
    let estates: [EstateSummaryResponse]
    let onClusterTap: (MapCluster) -> Void
    let onMapCameraChange: (MKCoordinateRegion) -> Void
    let onMapTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true

        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "estate")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        if let region = position.region {
            let current = mapView.region
            let latDiff = abs(current.center.latitude - region.center.latitude)
            let lngDiff = abs(current.center.longitude - region.center.longitude)
            let spanDiff = abs(current.span.latitudeDelta - region.span.latitudeDelta)

            if latDiff > 0.0001 || lngDiff > 0.0001 || spanDiff > 0.0001 {
                mapView.setRegion(region, animated: true)
            }
        }

        context.coordinator.syncAnnotations(on: mapView, estates: estates)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapSceneView
        private var annotationById: [String: EstateAnnotation] = [:]

        init(_ parent: MapSceneView) {
            self.parent = parent
        }

        @objc func handleMapTap() {
            parent.onMapTap()
        }

        func syncAnnotations(on mapView: MKMapView, estates: [EstateSummaryResponse]) {
            let newIds = Set(estates.map(\.estate_id))
            let oldIds = Set(annotationById.keys)

            let removeIds = oldIds.subtracting(newIds)
            if !removeIds.isEmpty {
                let removing = removeIds.compactMap { annotationById.removeValue(forKey: $0) }
                mapView.removeAnnotations(removing)
            }

            let addEstates = estates.filter { annotationById[$0.estate_id] == nil }
            if !addEstates.isEmpty {
                let annotations = addEstates.map { estate in
                    let ann = EstateAnnotation(estate: estate)
                    annotationById[estate.estate_id] = ann
                    return ann
                }
                mapView.addAnnotations(annotations)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster", for: cluster) as! MKMarkerAnnotationView
                view.clusteringIdentifier = nil
                view.markerTintColor = .systemBlue
                view.glyphText = "\(cluster.memberAnnotations.count)"
                view.displayPriority = .required
                return view
            }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "estate", for: annotation) as! MKMarkerAnnotationView
            view.clusteringIdentifier = "estate"
            view.markerTintColor = .systemRed
            view.glyphImage = UIImage(systemName: "house.fill")
            view.displayPriority = .defaultHigh
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                let estates = cluster.memberAnnotations.compactMap { ($0 as? EstateAnnotation)?.estate }
                    .sorted { $0.estate_id < $1.estate_id }

                let mapped = MapCluster(
                    id: "cluster-\(estates.first?.estate_id ?? "unknown")-\(estates.last?.estate_id ?? "unknown")-\(estates.count)",
                    coordinate: cluster.coordinate,
                    estates: estates
                )
                parent.onClusterTap(mapped)
                return
            }

            if let estateAnn = view.annotation as? EstateAnnotation {
                let mapped = MapCluster(
                    id: estateAnn.estate.estate_id,
                    coordinate: estateAnn.coordinate,
                    estates: [estateAnn.estate]
                )
                parent.onClusterTap(mapped)
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onMapCameraChange(mapView.region)
        }
    }
}
