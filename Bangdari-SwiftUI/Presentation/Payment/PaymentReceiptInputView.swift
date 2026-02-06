import SwiftUI

// MARK: - Payment Receipt Input View

struct PaymentReceiptInputView: View {
    @State private var orderCode = ""
    @State private var navigateToReceipt = false

    var body: some View {
        VStack(spacing: 24) {
            // 안내 텍스트
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("결제 영수증 조회")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("주문번호를 입력하여 결제 영수증을 조회할 수 있습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // 주문번호 입력
            VStack(alignment: .leading, spacing: 8) {
                Text("주문번호")
                    .font(.headline)

                TextField("주문번호 입력", text: $orderCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal)

            // 조회 버튼
            Button {
                if !orderCode.trimmingCharacters(in: .whitespaces).isEmpty {
                    navigateToReceipt = true
                }
            } label: {
                Text("조회하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(orderCode.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(orderCode.isEmpty)
            .padding(.horizontal)

            Spacer()
        }
        .standardNavigationBar(title: "영수증 조회")
        .navigationDestination(isPresented: $navigateToReceipt) {
            PaymentReceiptView(orderCode: orderCode.trimmingCharacters(in: .whitespaces))
        }
    }
}

#Preview {
    NavigationStack {
        PaymentReceiptInputView()
    }
}
