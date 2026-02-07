import SwiftUI

struct FilterChipButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardBody3)
                .foregroundColor(isActive ? .deepWood : .gray75)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.gray0)
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.deepWood : Color.gray45, lineWidth: 2)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 8) {
        FilterChipButton(title: "보증금 순", isActive: false) {}
        FilterChipButton(title: "면적 순", isActive: true) {}
    }
}
