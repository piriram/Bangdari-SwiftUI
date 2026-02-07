import CoreLocation
import MapKit

enum MapViewHelpers {
    static func zoomRegion(
        from region: MKCoordinateRegion,
        scale: Double,
        clamp: ClosedRange<Double>
    ) -> MKCoordinateRegion {
        let nextLatDelta = (region.span.latitudeDelta * scale).clamped(to: clamp)
        let nextLngDelta = (region.span.longitudeDelta * scale).clamped(to: clamp)

        return MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(latitudeDelta: nextLatDelta, longitudeDelta: nextLngDelta)
        )
    }

    static func nearestEstateIndex(
        estates: [EstateSummaryResponse],
        to center: CLLocationCoordinate2D
    ) -> (index: Int, distance: Double) {
        guard !estates.isEmpty else { return (0, 0) }

        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        var nearestIndex = 0
        var minDistance = Double.infinity

        for (index, estate) in estates.enumerated() {
            let estateLocation = CLLocation(
                latitude: estate.geolocation.latitude,
                longitude: estate.geolocation.longitude
            )
            let distance = centerLocation.distance(from: estateLocation)

            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }

        return (nearestIndex, minDistance)
    }

    static func regionToFitCluster(
        _ cluster: MapCluster,
        currentSpan: MKCoordinateSpan
    ) -> MKCoordinateRegion {
        let estates = cluster.estates
        guard !estates.isEmpty else {
//            print("🔍 [Cluster Zoom] 빈 클러스터")
            return MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

//        print("🔍 [Cluster Zoom] 시작 - 현재 span: \(String(format: "%.6f", currentSpan.latitudeDelta)), 매물 수: \(estates.count)")
//        print("🔍 [Cluster Zoom] threshold: \(MapConstants.clusteringDisableThreshold)")

        let nearThreshold = MapConstants.clusteringDisableThreshold * 1.2
        if currentSpan.latitudeDelta <= nearThreshold {
            let targetSpan = MapConstants.clusteringDisableThreshold * 0.6
//            print("🔍 [Cluster Zoom] ✅ 분기1: 이미 충분히 확대됨 (\(String(format: "%.6f", currentSpan.latitudeDelta)) <= \(String(format: "%.6f", nearThreshold)))")
//            print("🔍 [Cluster Zoom] → 강제 확대: \(String(format: "%.6f", targetSpan))")
            return MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: targetSpan, longitudeDelta: targetSpan)
            )
        }

        let lats = estates.map(\.geolocation.latitude)
        let lngs = estates.map(\.geolocation.longitude)

        let minLat = lats.min() ?? cluster.coordinate.latitude
        let maxLat = lats.max() ?? cluster.coordinate.latitude
        let minLng = lngs.min() ?? cluster.coordinate.longitude
        let maxLng = lngs.max() ?? cluster.coordinate.longitude

        let rawRangeLat = maxLat - minLat
        let rawRangeLng = maxLng - minLng
//        print("🔍 [Cluster Zoom] 매물 범위 - lat: \(String(format: "%.6f", rawRangeLat)), lng: \(String(format: "%.6f", rawRangeLng))")

        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2

        let estateRangeLat = max((maxLat - minLat) * 1.4, 0.005)
        let estateRangeLng = max((maxLng - minLng) * 1.4, 0.005)
//        print("🔍 [Cluster Zoom] 매물 범위 (여유 40%): \(String(format: "%.6f", estateRangeLat))")

        let zoomInLat = currentSpan.latitudeDelta / 2
        let zoomInLng = currentSpan.longitudeDelta / 2
//        print("🔍 [Cluster Zoom] 2배 확대: \(String(format: "%.6f", zoomInLat))")

        var latDelta = min(estateRangeLat, zoomInLat)
        var lngDelta = min(estateRangeLng, zoomInLng)
//        print("🔍 [Cluster Zoom] min(매물범위, 2배확대): \(String(format: "%.6f", latDelta))")

        let targetThreshold = MapConstants.clusteringDisableThreshold * 0.8
        latDelta = min(latDelta, targetThreshold)
        lngDelta = min(lngDelta, targetThreshold)
//        print("🔍 [Cluster Zoom] ✅ 분기2: 일반 확대 로직")
//        print("🔍 [Cluster Zoom] → 최종 span: \(String(format: "%.6f", latDelta)) (threshold 강제: \(String(format: "%.6f", targetThreshold)))")
//        print("🔍 [Cluster Zoom] → 변화: \(String(format: "%.6f", currentSpan.latitudeDelta)) → \(String(format: "%.6f", latDelta)) (비율: \(String(format: "%.2f", latDelta / currentSpan.latitudeDelta))x)")

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
