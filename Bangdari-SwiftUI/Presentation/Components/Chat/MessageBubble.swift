import SwiftUI

// MARK: - Message Bubble

struct MessageBubble: View {
    let content: String
    let isMe: Bool

    var body: some View {
        Text(content)
            .font(.pretendard(.body2, .regular))
            .foregroundColor(isMe ? .gray0 : .gray90)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isMe ? Color.deepCoast : Color.gray15)
            .cornerRadius(18, corners: isMe ?
                [.topLeft, .topRight, .bottomLeft] :
                [.topLeft, .topRight, .bottomRight]
            )
            .shadow(color: .gray90.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}
