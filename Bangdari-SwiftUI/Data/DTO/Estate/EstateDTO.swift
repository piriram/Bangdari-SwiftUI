import Foundation

// MARK: - Estate Summary (리스트용)

struct EstateSummaryResponse: Decodable, Equatable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let area: Double
    let floors: Int
    let geolocation: Geolocation
    let files: [String]
    let distance: Double?
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let created_at: String
    let updated_at: String

    private enum CodingKeys: String, CodingKey {
        case estate_id
        case category
        case title
        case introduction
        case deposit
        case monthly_rent
        case built_year
        case area
        case floors
        case geolocation
        case files
        case thumbnails
        case distance
        case like_count
        case is_safe_estate
        case is_recommended
        case created_at, createdAt
        case updated_at, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estate_id = try container.decode(String.self, forKey: .estate_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        introduction = try container.decodeIfPresent(String.self, forKey: .introduction) ?? ""
        deposit = try Self.decodeFlexibleInt(from: container, forKey: .deposit, defaultValue: 0)
        monthly_rent = try Self.decodeFlexibleInt(from: container, forKey: .monthly_rent, defaultValue: 0)
        built_year = try container.decodeIfPresent(String.self, forKey: .built_year) ?? ""
        area = try Self.decodeFlexibleDouble(from: container, forKey: .area, defaultValue: 0)
        floors = try Self.decodeFlexibleInt(from: container, forKey: .floors, defaultValue: 0)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        if let decodedFiles = try container.decodeIfPresent([String].self, forKey: .files) {
            files = decodedFiles
        } else {
            files = try container.decodeIfPresent([String].self, forKey: .thumbnails) ?? []
        }
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        like_count = try Self.decodeFlexibleInt(from: container, forKey: .like_count, defaultValue: 0)
        is_safe_estate = try container.decodeIfPresent(Bool.self, forKey: .is_safe_estate) ?? false
        is_recommended = try container.decodeIfPresent(Bool.self, forKey: .is_recommended) ?? false
        if let createdAtValue = try container.decodeIfPresent(String.self, forKey: .created_at) {
            created_at = createdAtValue
        } else {
            created_at = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        }
        if let updatedAtValue = try container.decodeIfPresent(String.self, forKey: .updated_at) {
            updated_at = updatedAtValue
        } else {
            updated_at = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        }
    }

    private static func decodeFlexibleInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
        defaultValue: Int
    ) throws -> Int {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? container.decode(String.self, forKey: key),
           let intValue = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return intValue
        }
        return defaultValue
    }

    private static func decodeFlexibleDouble(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
        defaultValue: Double
    ) throws -> Double {
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? container.decode(String.self, forKey: key),
           let doubleValue = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return doubleValue
        }
        return defaultValue
    }
}

// MARK: - Geolocation

struct Geolocation: Decodable, Equatable {
    let longitude: Double
    let latitude: Double
}

// MARK: - Estate List Response

struct EstateListResponse: Decodable {
    let data: [EstateSummaryResponse]
}

// MARK: - Estate Pagination Response (cursor 기반)

struct EstatePaginationResponse: Decodable {
    let data: [EstateSummaryResponse]
    let next_cursor: String

    var hasMore: Bool {
        next_cursor != "0"
    }
}

// MARK: - Estate Detail Response

struct EstateDetailResponse: Decodable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let description: String
    let deposit: Int
    let monthly_rent: Int
    let reservation_price: Int
    let built_year: String
    let maintenance_fee: Int
    let parking_count: Int
    let area: Double
    let floors: String  // API가 Int로 올 수 있어서 커스텀 디코딩
    let options: EstateOptions
    let geolocation: Geolocation
    let files: [String]
    let creator: UserInfo
    let is_liked: Bool
    let is_reserved: Bool
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let comments: [EstateComment]
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case estate_id, category, title, introduction, description
        case deposit, monthly_rent, reservation_price
        case built_year, maintenance_fee, parking_count
        case area, floors, options, geolocation, files, thumbnails, creator
        case is_liked, is_reserved, like_count, is_safe_estate, is_recommended
        case comments, createdAt, updatedAt, created_at, updated_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estate_id = try container.decode(String.self, forKey: .estate_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        introduction = try container.decodeIfPresent(String.self, forKey: .introduction) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        deposit = try container.decode(Int.self, forKey: .deposit)
        monthly_rent = try container.decode(Int.self, forKey: .monthly_rent)
        reservation_price = try container.decode(Int.self, forKey: .reservation_price)
        built_year = try container.decodeIfPresent(String.self, forKey: .built_year) ?? ""
        maintenance_fee = try container.decodeIfPresent(Int.self, forKey: .maintenance_fee) ?? 0
        parking_count = try container.decodeIfPresent(Int.self, forKey: .parking_count) ?? 0
        area = try container.decode(Double.self, forKey: .area)
        // floors: String 또는 Int로 올 수 있음
        if let floorsString = try? container.decode(String.self, forKey: .floors) {
            floors = floorsString
        } else if let floorsInt = try? container.decode(Int.self, forKey: .floors) {
            floors = "\(floorsInt)층"
        } else {
            floors = "-"
        }
        options = try container.decode(EstateOptions.self, forKey: .options)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        if let decodedFiles = try container.decodeIfPresent([String].self, forKey: .files) {
            files = decodedFiles
        } else {
            files = try container.decodeIfPresent([String].self, forKey: .thumbnails) ?? []
        }
        creator = try container.decode(UserInfo.self, forKey: .creator)
        is_liked = try container.decode(Bool.self, forKey: .is_liked)
        is_reserved = try container.decode(Bool.self, forKey: .is_reserved)
        like_count = try container.decodeIfPresent(Int.self, forKey: .like_count) ?? 0
        is_safe_estate = try container.decode(Bool.self, forKey: .is_safe_estate)
        is_recommended = try container.decode(Bool.self, forKey: .is_recommended)
        comments = try container.decodeIfPresent([EstateComment].self, forKey: .comments) ?? []
        if let createdAtValue = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = createdAtValue
        } else {
            createdAt = try container.decode(String.self, forKey: .created_at)
        }
        if let updatedAtValue = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = updatedAtValue
        } else {
            updatedAt = try container.decode(String.self, forKey: .updated_at)
        }
    }
}

// MARK: - Estate Options

struct EstateOptions: Decodable {
    let option1: Bool
    let option2: Bool
    let option3: Bool
    let option4: Bool
    let option5: Bool
    let option6: Bool
    let option7: Bool
    let option8: Bool
    let option9: Bool
    let option10: Bool
    private let serverOptionNames: [String]

    private enum CodingKeys: String, CodingKey {
        case option1, option2, option3, option4, option5
        case option6, option7, option8, option9, option10
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var collectedNames: [String] = []
        option1 = try Self.decodeFlexibleOption(from: container, forKey: .option1, names: &collectedNames)
        option2 = try Self.decodeFlexibleOption(from: container, forKey: .option2, names: &collectedNames)
        option3 = try Self.decodeFlexibleOption(from: container, forKey: .option3, names: &collectedNames)
        option4 = try Self.decodeFlexibleOption(from: container, forKey: .option4, names: &collectedNames)
        option5 = try Self.decodeFlexibleOption(from: container, forKey: .option5, names: &collectedNames)
        option6 = try Self.decodeFlexibleOption(from: container, forKey: .option6, names: &collectedNames)
        option7 = try Self.decodeFlexibleOption(from: container, forKey: .option7, names: &collectedNames)
        option8 = try Self.decodeFlexibleOption(from: container, forKey: .option8, names: &collectedNames)
        option9 = try Self.decodeFlexibleOption(from: container, forKey: .option9, names: &collectedNames)
        option10 = try Self.decodeFlexibleOption(from: container, forKey: .option10, names: &collectedNames)
        serverOptionNames = collectedNames
    }

    private static func decodeFlexibleOption(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
        names: inout [String]
    ) throws -> Bool {
        if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            switch trimmed.lowercased() {
            case "true", "1", "y", "yes":
                return true
            case "false", "0", "n", "no":
                return false
            default:
                break
            }
            if !trimmed.isEmpty {
                names.append(trimmed)
                return true
            }
        }
        return false
    }

    // 옵션 이름 매핑
    static let optionNames = [
        "에어컨", "냉장고", "세탁기", "가스레인지", "인덕션",
        "전자레인지", "책상", "침대", "옷장", "신발장"
    ]

    var enabledOptions: [String] {
        if !serverOptionNames.isEmpty {
            return serverOptionNames
        }
        var result: [String] = []
        let values = [option1, option2, option3, option4, option5,
                      option6, option7, option8, option9, option10]
        for (index, enabled) in values.enumerated() where enabled {
            result.append(Self.optionNames[index])
        }
        return result
    }
}

// MARK: - User Info

struct UserInfo: Decodable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}

// MARK: - Estate Comment

struct EstateComment: Decodable {
    let comment_id: String
    let content: String
    let creator: UserInfo
    let createdAt: String
    let updatedAt: String
    let replies: [EstateComment]?
}

// MARK: - Like Request/Response

struct EstateLikeRequest: Encodable {
    let like_status: Bool
}

struct EstateLikeResponse: Decodable {
    let like_status: Bool
}

// MARK: - Estate Topic

struct EstateTopic: Decodable {
    let title: String
    let content: String
    let date: String
    let link: String?
}

struct EstateTopicResponse: Decodable {
    let data: [EstateTopic]
}

// MARK: - Banner

struct BannerResponse: Decodable {
    let data: [Banner]
}

struct Banner: Decodable {
    let banner_id: String
    let title: String
    let image: String
    let link: String?

    private enum CodingKeys: String, CodingKey {
        case banner_id, id, _id
        case title, name
        case image, imageUrl, img
        case link, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID
        if let bannerId = try container.decodeIfPresent(String.self, forKey: .banner_id) {
            banner_id = bannerId
        } else if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            banner_id = id
        } else if let mongoId = try container.decodeIfPresent(String.self, forKey: ._id) {
            banner_id = mongoId
        } else {
            banner_id = UUID().uuidString
        }

        // Title
        if let t = try container.decodeIfPresent(String.self, forKey: .title) {
            title = t
        } else if let n = try container.decodeIfPresent(String.self, forKey: .name) {
            title = n
        } else {
            title = ""
        }

        // Image
        if let img = try container.decodeIfPresent(String.self, forKey: .image) {
            image = img
        } else if let imgUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) {
            image = imgUrl
        } else if let i = try container.decodeIfPresent(String.self, forKey: .img) {
            image = i
        } else {
            image = ""
        }

        // Link
        if let l = try container.decodeIfPresent(String.self, forKey: .link) {
            link = l
        } else {
            link = try container.decodeIfPresent(String.self, forKey: .url)
        }
    }
}
