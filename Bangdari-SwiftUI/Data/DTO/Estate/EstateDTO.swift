import Foundation

// MARK: - Estate Summary (리스트용)

struct EstateSummaryResponse: Decodable, Equatable {
    let estate_id: String
    let category: String
    let title: String
    let deposit: Int
    let monthly_rent: Int
    let area: Double
    let geolocation: Geolocation
    let files: [String]
    let distance: Double?

    private enum CodingKeys: String, CodingKey {
        case estate_id
        case category
        case title
        case deposit
        case monthly_rent
        case area
        case geolocation
        case files
        case distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estate_id = try container.decode(String.self, forKey: .estate_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        deposit = try container.decode(Int.self, forKey: .deposit)
        monthly_rent = try container.decode(Int.self, forKey: .monthly_rent)
        area = try container.decode(Double.self, forKey: .area)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
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
    let deposit: Int
    let monthly_rent: Int
    let reservation_price: Int
    let area: Double
    let floors: String  // API가 Int로 올 수 있어서 커스텀 디코딩
    let options: EstateOptions
    let geolocation: Geolocation
    let files: [String]
    let creator: UserInfo
    let is_liked: Bool
    let is_reserved: Bool
    let is_safe_estate: Bool
    let is_recommended: Bool
    let comments: [EstateComment]
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case estate_id, category, title, deposit, monthly_rent, reservation_price
        case area, floors, options, geolocation, files, creator
        case is_liked, is_reserved, is_safe_estate, is_recommended
        case comments, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estate_id = try container.decode(String.self, forKey: .estate_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        deposit = try container.decode(Int.self, forKey: .deposit)
        monthly_rent = try container.decode(Int.self, forKey: .monthly_rent)
        reservation_price = try container.decode(Int.self, forKey: .reservation_price)
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
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        creator = try container.decode(UserInfo.self, forKey: .creator)
        is_liked = try container.decode(Bool.self, forKey: .is_liked)
        is_reserved = try container.decode(Bool.self, forKey: .is_reserved)
        is_safe_estate = try container.decode(Bool.self, forKey: .is_safe_estate)
        is_recommended = try container.decode(Bool.self, forKey: .is_recommended)
        comments = try container.decodeIfPresent([EstateComment].self, forKey: .comments) ?? []
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
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

    private enum CodingKeys: String, CodingKey {
        case option1, option2, option3, option4, option5
        case option6, option7, option8, option9, option10
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        option1 = try Self.decodeFlexibleBool(from: container, forKey: .option1)
        option2 = try Self.decodeFlexibleBool(from: container, forKey: .option2)
        option3 = try Self.decodeFlexibleBool(from: container, forKey: .option3)
        option4 = try Self.decodeFlexibleBool(from: container, forKey: .option4)
        option5 = try Self.decodeFlexibleBool(from: container, forKey: .option5)
        option6 = try Self.decodeFlexibleBool(from: container, forKey: .option6)
        option7 = try Self.decodeFlexibleBool(from: container, forKey: .option7)
        option8 = try Self.decodeFlexibleBool(from: container, forKey: .option8)
        option9 = try Self.decodeFlexibleBool(from: container, forKey: .option9)
        option10 = try Self.decodeFlexibleBool(from: container, forKey: .option10)
    }

    private static func decodeFlexibleBool(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? container.decode(String.self, forKey: key) {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "y", "yes":
                return true
            case "false", "0", "n", "no":
                return false
            default:
                break
            }
        }
        throw DecodingError.typeMismatch(
            Bool.self,
            DecodingError.Context(
                codingPath: container.codingPath + [key],
                debugDescription: "Expected Bool/Int/String for \(key.stringValue)"
            )
        )
    }

    // 옵션 이름 매핑
    static let optionNames = [
        "에어컨", "냉장고", "세탁기", "가스레인지", "인덕션",
        "전자레인지", "책상", "침대", "옷장", "신발장"
    ]

    var enabledOptions: [String] {
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
    let link: String
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
