import MapKit
import SwiftUI

// MARK: - Map View

struct EstateMapView: View {
    @StateObject private var intent = MapIntent()
    @State private var position: MapCameraPosition = .region(.defaultRegion)
    @State private var selectedEstate: EstateSummaryResponse?

    var body: some View {
        ZStack {
            mapContent

            // 현재 위치 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    currentLocationButton
                }
            }
            .padding()

            // 로딩 인디케이터
            if intent.state.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
        }
        .onChange(of: intent.state.selectedEstate) { _, newValue in
            selectedEstate = newValue
        }
        .sheet(item: $selectedEstate) { estate in
            estatePreview(estate)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .navigationTitle("지도")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                searchButton
            }
        }
        .onAppear {
            intent.requestLocationPermission()
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $position) {
            // 매물 마커
            ForEach(intent.state.estates, id: \.estate_id) { estate in
                Annotation(
                    estate.title,
                    coordinate: CLLocationCoordinate2D(
                        latitude: estate.geolocation.latitude,
                        longitude: estate.geolocation.longitude
                    )
                ) {
                    estateMarker(estate)
                }
            }

            // 현재 위치
            UserAnnotation()
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            intent.updateRegion(context.region)
        }
    }

    // MARK: - Estate Marker

    private func estateMarker(_ estate: EstateSummaryResponse) -> some View {
        Button {
            intent.selectEstate(estate)
        } label: {
            VStack(spacing: 0) {
                Text(priceText(estate))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.brown)
                    .cornerRadius(4)

                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.brown)
                    .rotationEffect(.degrees(180))
                    .offset(y: -2)
            }
        }
    }

    // MARK: - Current Location Button

    private var currentLocationButton: some View {
        Button {
            intent.moveToCurrentLocation()
            if let location = CLLocationManager().location {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.brown)
                .padding(12)
                .background(.ultraThickMaterial)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }

    // MARK: - Search Button

    private var searchButton: some View {
        Button {
            Task {
                await intent.loadEstatesInCurrentRegion()
            }
        } label: {
            Text("현 지도에서 검색")
                .font(.caption)
        }
    }

    // MARK: - Estate Preview Sheet

    private func estatePreview(_ estate: EstateSummaryResponse) -> some View {
        NavigationStack {
            HStack(spacing: 12) {
                // 썸네일
                AsyncImage(url: imageURL(estate)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 100, height: 80)
                .clipped()
                .cornerRadius(8)

                // 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(estate.category)
                        .font(.caption)
                        .foregroundColor(.brown)

                    Text(estate.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Text(priceText(estate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 상세 보기 버튼
                NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func priceText(_ estate: EstateSummaryResponse) -> String {
        if estate.monthly_rent > 0 {
            return "\(estate.deposit)/\(estate.monthly_rent)"
        } else {
            return "전세 \(estate.deposit)"
        }
    }

    private func imageURL(_ estate: EstateSummaryResponse) -> URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: Secrets.baseURL + "/" + first)
    }
}

// MARK: - EstateSummaryResponse Identifiable

extension EstateSummaryResponse: Identifiable {
    var id: String { estate_id }
}

#Preview {
    NavigationStack {
        EstateMapView()
    }
}
