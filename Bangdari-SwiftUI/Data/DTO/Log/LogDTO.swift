import Foundation

// MARK: - Server Log DTOs

struct ServerLogResponse: Decodable {
    let count: Int
    let logs: [ServerLogEntry]
}

struct ServerLogEntry: Decodable, Identifiable {
    let date: String
    let name: String
    let method: String
    let routePath: String
    let body: String
    let contentType: String
    let statusCode: String

    var id: String {
        "\(date)-\(method)-\(routePath)-\(statusCode)"
    }

    enum CodingKeys: String, CodingKey {
        case date
        case name
        case method
        case routePath = "route_path"
        case body
        case contentType
        case statusCode = "status_code"
    }
}
