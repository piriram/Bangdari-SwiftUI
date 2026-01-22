import Kingfisher
import MapKit
import SwiftUI

// MARK: - Map View

struct EstateMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent = MapIntent()
    @State private var position: MapCameraPosition = .region(.defaultRegion)
    @State private var selectedEstate: EstateSummaryResponse?
    @State private var isDepositFilterActive: Bool = true
    @State private var depositLowerBound: Double = 2_000_000
    @State private var depositUpperBound: Double = 90_000_000
    @State private var selectedEstateId: String?

    var body: some View {
        ZStack {
            mapContent
                .ignoresSafeArea()

            VStack(spacing: 12) {
                navigationHeader
                SearchBarButton(placeholder: "지역 또는 매물을 검색하세요", style: .bordered) {
                    // TODO: 검색 화면으로 이동
                }
                filterChipRow
                if isDepositFilterActive {
                    depositRangeCard
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

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

            if isDepositFilterActive {
                bottomEstateCarousel
            }
        }
        .onChange(of: intent.state.selectedEstate) { _, newValue in
            selectedEstate = newValue
            selectedEstateId = newValue?.estate_id
        }
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
            if isDepositFilterActive {
                ForEach(intent.state.estates) { estate in
                    Annotation(estate.title, coordinate: estate.geolocation.coordinate) {
                        estatePin(estate)
                    }
                }
            } else {
                // 클러스터 마커
                ForEach(intent.state.clusters) { cluster in
                    Annotation(
                        cluster.isSingle ? (cluster.firstEstate?.title ?? "") : "\(cluster.count)개 매물",
                        coordinate: cluster.coordinate
                    ) {
                        clusterMarker(cluster)
                    }
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
            intent.updateClusters()
        }
    }

    // MARK: - Cluster Marker

    private func clusterMarker(_ cluster: MapCluster) -> some View {
        Button {
            if cluster.isSingle, let estate = cluster.firstEstate {
                intent.selectEstate(estate)
            } else {
                // 클러스터 탭 시 줌인
                zoomToCluster(cluster)
            }
        } label: {
            if cluster.isSingle, let estate = cluster.firstEstate {
                // 단일 매물 마커
                VStack(spacing: 0) {
                    Text(priceText(estate))
                        .font(.pretendardCaption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray0)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.deepCream)
                        .cornerRadius(6)

                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.deepCream)
                        .rotationEffect(.degrees(180))
                        .offset(y: -2)
                }
            } else {
                // 클러스터 마커
                ZStack {
                    Circle()
                        .fill(Color.brightCream.opacity(0.4))
                        .frame(width: clusterSize(cluster.count) + 12, height: clusterSize(cluster.count) + 12)

                    Circle()
                        .fill(Color.deepCream)
                        .frame(width: clusterSize(cluster.count), height: clusterSize(cluster.count))

                    Text("\(cluster.count)")
                        .font(.pretendardBody2Bold)
                        .foregroundColor(.gray0)
                }
            }
        }
    }

    private func clusterSize(_ count: Int) -> CGFloat {
        let base: CGFloat = 44
        if count >= 100 { return base + 16 }
        if count >= 50 { return base + 8 }
        return base
    }

    private func estatePin(_ estate: EstateSummaryResponse) -> some View {
        Button {
            selectedEstateId = estate.estate_id
            scrollToEstate(estate)
        } label: {
            VStack(spacing: 6) {
                Text(priceText(estate))
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.deepWood)
                    .cornerRadius(6)

                HStack(spacing: 8) {
                    KFImage.auth(url: imageURL(estate))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .background(Color.gray15)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(estate.title)
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray90)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray0)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private func zoomToCluster(_ cluster: MapCluster) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: intent.state.region.span.latitudeDelta / 2,
            longitudeDelta: intent.state.region.span.longitudeDelta / 2
        )
        position = .region(MKCoordinateRegion(center: cluster.coordinate, span: newSpan))
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
            Image(dsIcon: .focus)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.gray75)
                .frame(width: 44, height: 44)
                .background(Color.gray0)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                .font(.pretendardCaption1)
        }
    }

    // MARK: - Header / Filters

    private var navigationHeader: some View {
        HStack(spacing: 12) {
            // 뒤로가기 버튼
            Button {
                dismiss()
            } label: {
                Image(dsIcon: .chevron)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray90)
                    .padding(10)
                    .background(Color.gray0)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }

            // 위치 표시
            HStack(spacing: 6) {
                Image(dsIcon: .location)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.deepCoast)

                Text("문래역, 영등포구")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray0)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

            Spacer()

            // 필터/옵션 버튼
            Button {
                // TODO: 옵션
            } label: {
                Image(dsIcon: .sort)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray90)
                    .padding(10)
                    .background(Color.gray0)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var filterChipRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "평수 선택", isActive: false)
            filterChip(title: "월세 선택", isActive: false)
            filterChip(title: "보증금 선택", isActive: isDepositFilterActive)
        }
    }

    private func filterChip(title: String, isActive: Bool) -> some View {
        Button {
            if title == "보증금 선택" {
                isDepositFilterActive.toggle()
            }
        } label: {
            Text(title)
                .font(.pretendardCaption1)
                .foregroundColor(isActive ? .deepWood : .gray75)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isActive ? Color.brightCream : Color.gray0)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color.deepWood : Color.gray30, lineWidth: 1)
                )
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var depositRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(formatDeposit(depositLowerBound)) ~ \(formatDeposit(depositUpperBound))")
                .font(.pretendardBody2)
                .foregroundColor(.gray90)

            RangeSlider(
                lowerValue: $depositLowerBound,
                upperValue: $depositUpperBound,
                bounds: 0...100_000_000
            )

            HStack {
                Text("최소")
                Spacer()
                Text("최대")
            }
            .font(.pretendardCaption2)
            .foregroundColor(.gray60)
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var bottomEstateCarousel: some View {
        VStack {
            Spacer()
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(intent.state.estates) { estate in
                            bottomEstateCard(estate)
                                .frame(width: UIScreen.main.bounds.width * 0.85)
                                .id(estate.estate_id)
                                .onTapGesture {
                                    selectedEstateId = estate.estate_id
                                    position = .region(MKCoordinateRegion(
                                        center: estate.geolocation.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    ))
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 150)
                .onChange(of: selectedEstateId) { _, newValue in
                    guard let newValue else { return }
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func bottomEstateCard(_ estate: EstateSummaryResponse) -> some View {
        HStack(spacing: 12) {
            KFImage.auth(url: imageURL(estate))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 96, height: 96)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(estate.category)
                    .font(.pretendardCaption1)
                    .foregroundColor(.deepWood)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brightCream)
                    .cornerRadius(8)

                Text(estate.title)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                Text(priceText(estate))
                    .font(.pretendardTitle1)
                    .foregroundColor(.gray90)

                Text("\(String(format: "%.1f", estate.area))m²")
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray75)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
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

    private func formatDeposit(_ value: Double) -> String {
        let intValue = Int(value)
        if intValue >= 100_000_000 {
            let eok = intValue / 100_000_000
            let cheonman = (intValue % 100_000_000) / 10_000_000
            return cheonman > 0 ? "\(eok)억 \(cheonman)천만" : "\(eok)억"
        }
        if intValue >= 10_000_000 {
            let cheonman = intValue / 10_000_000
            return "\(cheonman)천만"
        }
        if intValue >= 1_000_000 {
            let baekman = intValue / 1_000_000
            return "\(baekman)백만"
        }
        return "\(intValue)"
    }

    private func scrollToEstate(_ estate: EstateSummaryResponse) {
        selectedEstateId = estate.estate_id
    }
}

// MARK: - Range Slider

private struct RangeSlider: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let range = bounds.upperBound - bounds.lowerBound
            let lowerX = CGFloat((lowerValue - bounds.lowerBound) / range) * width
            let upperX = CGFloat((upperValue - bounds.lowerBound) / range) * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray30)
                    .frame(height: 4)

                Capsule()
                    .fill(Color.deepWood)
                    .frame(width: max(upperX - lowerX, 0), height: 4)
                    .offset(x: lowerX)

                sliderThumb
                    .position(x: lowerX, y: 2)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = min(max(0, value.location.x), upperX)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            lowerValue = min(max(bounds.lowerBound, newValue), upperValue)
                        }
                    )

                sliderThumb
                    .position(x: upperX, y: 2)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = max(min(width, value.location.x), lowerX)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            upperValue = max(min(bounds.upperBound, newValue), lowerValue)
                        }
                    )
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }

    private var sliderThumb: some View {
        Circle()
            .stroke(Color.deepWood, lineWidth: 2)
            .background(Circle().fill(Color.gray0))
            .frame(width: 20, height: 20)
    }
}

// MARK: - EstateSummaryResponse Identifiable

extension EstateSummaryResponse: Identifiable {
    var id: String { estate_id }
}

private extension Geolocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    NavigationStack {
        EstateMapView()
    }
}
