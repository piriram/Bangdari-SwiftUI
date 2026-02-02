import SwiftUI

// MARK: - Server Log View

struct ServerLogView: View {
    @StateObject private var intent = ServerLogIntent()
    @State private var selectedLog: ServerLogEntry?

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
        .standardNavigationBar(title: "서버 요청 로그")
        .sheet(item: $selectedLog) { log in
            LogDetailSheet(log: log)
        }
        .task {
            await intent.loadLogs()
        }
    }

    // MARK: - Log List

    private var logList: some View {
        List {
            ForEach(intent.state.logs) { log in
                Button {
                    selectedLog = log
                } label: {
                    logRow(log)
                }
                .buttonStyle(.plain)
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

// MARK: - Log Detail Sheet

struct LogDetailSheet: View {
    let log: ServerLogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var showCopyToast = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 요약 정보
                    summarySection

                    Divider()

                    // 요청 정보
                    requestSection

                    Divider()

                    // Body
                    bodySection
                }
                .padding()
            }
            .navigationTitle("로그 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray75)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showCopyToast {
                    CopyToast()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요약")
                .font(.headline)

            HStack(spacing: 12) {
                Badge(text: log.method, color: methodColor(log.method))
                Badge(text: log.statusCode, color: statusColor(log.statusCode))
            }

            DetailRow(title: "시간", value: formatFullDate(log.date))
            DetailRow(title: "요청자", value: log.name)
        }
    }

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요청 정보")
                .font(.headline)

            DetailRow(title: "경로", value: log.routePath, copyable: true)
            DetailRow(title: "Content-Type", value: log.contentType.isEmpty ? "없음" : log.contentType)
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("요청 본문")
                    .font(.headline)

                Spacer()

                if !log.body.isEmpty && log.body != "{}" {
                    Button {
                        copyToClipboard(log.body)
                    } label: {
                        Label("복사", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if log.body.isEmpty || log.body == "{}" {
                Text("본문 없음")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(formatJSON(log.body))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Helper Views

    private struct Badge: View {
        let text: String
        let color: Color

        var body: some View {
            Text(text)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(6)
        }
    }

    private struct DetailRow: View {
        let title: String
        let value: String
        var copyable: Bool = false
        @State private var showCopyToast = false

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if copyable {
                        Button {
                            UIPasteboard.general.string = value
                            showCopyToast = true
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                showCopyToast = false
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                }

                Text(value)
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
        }
    }

    private struct CopyToast: View {
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("복사되었습니다")
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 4)
        }
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

    private func formatFullDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let output = DateFormatter()
            output.dateFormat = "yyyy년 MM월 dd일 HH:mm:ss"
            output.locale = Locale(identifier: "ko_KR")
            return output.string(from: date)
        }
        return dateString
    }

    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopyToast = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopyToast = false
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ServerLogView()
    }
}

#Preview("Detail Sheet") {
    LogDetailSheet(log: ServerLogEntry(
        date: "2025-05-08T11:43:17.000Z",
        name: "김새싹",
        method: "POST",
        routePath: "/v1/users/login",
        body: "{\"email\":\"test@example.com\",\"password\":\"••••••\"}",
        contentType: "application/json",
        statusCode: "200"
    ))
}
