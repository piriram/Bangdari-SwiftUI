import SwiftUI

// MARK: - Server Log View

struct ServerLogView: View {
    @StateObject private var intent = ServerLogIntent()

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.logs.isEmpty {
                ProgressView()
            } else if let error = intent.state.errorMessage, intent.state.logs.isEmpty {
                errorView(error)
            } else if intent.state.logs.isEmpty {
                emptyView
            } else {
                logList
            }
        }
        .navigationTitle("서버 요청 로그")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await intent.loadLogs()
        }
    }

    // MARK: - Log List

    private var logList: some View {
        List {
            ForEach(intent.state.logs) { log in
                logRow(log)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await intent.refresh()
        }
    }

    // MARK: - Row

    private func logRow(_ log: ServerLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(log.method)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(methodColor(log.method).opacity(0.12))
                    .foregroundColor(methodColor(log.method))
                    .cornerRadius(4)

                Text(log.statusCode)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(log.statusCode).opacity(0.12))
                    .foregroundColor(statusColor(log.statusCode))
                    .cornerRadius(4)

                Spacer()

                Text(formatDate(log.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(log.routePath)
                .font(.footnote)
                .foregroundColor(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(log.name)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !log.contentType.isEmpty {
                    Text(log.contentType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if !log.body.isEmpty, log.body != "{}" {
                Text(log.body)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Empty / Error

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("요청 로그가 없습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task { await intent.loadLogs() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Helpers

    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .secondary
        }
    }

    private func statusColor(_ status: String) -> Color {
        guard let code = Int(status) else { return .secondary }
        switch code {
        case 200...299: return .green
        case 400...499: return .orange
        case 500...599: return .red
        default: return .secondary
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let output = DateFormatter()
            output.dateFormat = "yyyy.MM.dd HH:mm"
            return output.string(from: date)
        }
        return String(dateString.prefix(16))
    }
}

#Preview {
    NavigationStack {
        ServerLogView()
    }
}
