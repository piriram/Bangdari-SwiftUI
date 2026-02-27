import SwiftUI

// MARK: - My Order List View

struct MyOrderListView: View {
    @StateObject private var intent = MyOrderListIntent()
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            if intent.state.isLoading {
                ProgressView("주문 목록을 불러오는 중...")
            } else if intent.state.orders.isEmpty {
                emptyView
            } else {
                orderList
            }
        }
        .standardNavigationBar(title: "내 주문 목록")
        .task {
            await intent.loadOrders()
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {
                intent.clearError()
            }
        } message: {
            Text(intent.state.errorMessage ?? "")
        }
        .onChange(of: intent.state.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("주문 내역이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Order List

    private var orderList: some View {
        List(intent.state.orders) { order in
            NavigationLink {
                PaymentReceiptView(orderCode: order.order_code)
            } label: {
                OrderRowView(order: order)
            }
        }
    }
}

// MARK: - Order Row View

struct OrderRowView: View {
    let order: OrderResponse

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일
            AsyncImage(url: URL(string: order.estate.thumbnails.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(order.estate.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(formattedPrice(order.estate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formattedDate(order.paidAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("주문번호: \(order.order_code)")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formattedPrice(_ estate: EstateSummaryForOrder) -> String {
        let deposit = estate.deposit.formatted()
        let rent = estate.monthly_rent.formatted()
        return "보증금 \(deposit)만원 / 월세 \(rent)만원"
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        displayFormatter.timeStyle = .short
        displayFormatter.locale = Locale(identifier: "ko_KR")
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        MyOrderListView()
    }
}
