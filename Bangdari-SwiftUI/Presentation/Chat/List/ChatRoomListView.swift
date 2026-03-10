import Kingfisher
import SwiftUI

// MARK: - Chat Room List View

struct ChatRoomListView: View {
    @StateObject private var intent = ChatRoomListIntent()

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.chatRooms.isEmpty {
                loadingView
            } else if let error = intent.state.errorMessage, intent.state.chatRooms.isEmpty {
                errorView(error)
            } else if intent.state.chatRooms.isEmpty {
                emptyView
            } else {
                chatRoomList
            }
        }
        .standardNavigationBar(title: "채팅")
        .task {
            await intent.loadChatRooms()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await intent.loadChatRooms() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("채팅 내역이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("매물 상세 페이지에서\n집주인과 바로 대화를 시작해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chatRoomList: some View {
        List(intent.state.chatRooms) { room in
            NavigationLink(destination: ChatRoomView(roomId: room.room_id, opponent: room.opponent(myUserId: intent.state.myUserId))) {
                chatRoomRow(room)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await intent.refresh()
        }
    }

    private func chatRoomRow(_ room: ChatRoomResponse) -> some View {
        let opponent = room.opponent(myUserId: intent.state.myUserId)

        // API 응답에 unreadCount가 있으면 사용, 없으면 주석 처리
        // let unreadCount = room.unreadCount ?? 0

        return HStack(spacing: 12) {
            // 프로필 이미지
            profileImage(opponent?.profileImage)

            // 닉네임 + 마지막 메시지
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(opponent?.nick ?? "알 수 없음")
                        .font(.pretendard(.body1, .semiBold))
                        .foregroundColor(.gray90)
                        .lineLimit(1)

                    // 읽지 않은 메시지 배지 (API 지원 시 활성화)
                    // if unreadCount > 0 {
                    //     Badge(text: "\(unreadCount)", style: .primary)
                    // }
                }

                if let lastChat = room.lastChat {
                    Text(lastChat.content.isEmpty ? "[파일]" : lastChat.content)
                        .font(.pretendard(.body2, .regular))
                        .foregroundColor(.gray60)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 시간
            if let lastChat = room.lastChat {
                Text(formatDate(lastChat.createdAt))
                    .font(.pretendard(.caption1, .medium))
                    .foregroundColor(.gray60)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func profileImage(_ urlString: String?) -> some View {
        if let urlString,
           let url = URL(string: Secrets.baseURL + "/" + urlString) {
            KFImage.auth(url: url)
                .placeholder {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                        }
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            // 다른 형식 시도
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return ""
            }
            return formatRelativeDate(date)
        }

        return formatRelativeDate(date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatRoomListView()
    }
}
