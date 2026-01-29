import SwiftUI

// MARK: - Reservation Success View

struct ReservationSuccessView: View {
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 체크마크 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.deepCoast)

            VStack(spacing: 12) {
                Text("예약이 완료되었습니다")
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray90)

                Text("중개사가 확인 후 연락드릴 예정입니다")
                    .font(.pretendard(.body2))
                    .foregroundColor(.gray60)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // 확인 버튼
            Button {
                onConfirm()
            } label: {
                Text("확인")
                    .font(.pretendard(.body1, .bold))
                    .foregroundColor(.gray0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.deepCream)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.gray0)
    }
}

#Preview {
    ReservationSuccessView {
        print("확인 버튼 클릭")
    }
}
