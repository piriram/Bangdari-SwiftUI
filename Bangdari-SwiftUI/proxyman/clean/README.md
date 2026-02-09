# 목업 데이터 (정리 완료)

> 서버 종료 후 포트폴리오 시연용 목업 데이터

## 📋 파일 목록

### 🏠 Estate (부동산)
| 파일 | 설명 | 크기 |
|------|------|------|
| `hot-estates.json` | HOT 매물 목록 | 6.8KB |
| `today-estates.json` | 오늘의 매물 | 2.3KB |
| `geolocation.json` | 위치 기반 매물 검색 | 1.2MB |
| `similar-estates.json` | 유사 매물 추천 | 6.7KB |
| `today-topic.json` | 오늘의 토픽 | 5.0KB |
| `estate-detail-*.json` | 매물 상세 정보 (3개) | 각 1.3KB |

### 👤 User (사용자)
| 파일 | 설명 | 크기 |
|------|------|------|
| `user-profile.json` | 내 프로필 정보 | 206B |

### 🎨 Banner (배너)
| 파일 | 설명 | 크기 |
|------|------|------|
| `banners-main.json` | 메인 화면 배너 | 730B |

### 💬 Chat (채팅)
| 파일 | 설명 | 크기 |
|------|------|------|
| `chat-rooms.json` | 채팅방 목록 | 1.1KB |
| `chat-messages.json` | 채팅 메시지 내역 | 974B |

### 🎥 Video (영상)
| 파일 | 설명 | 크기 |
|------|------|------|
| `videos.json` | 영상 목록 | 3.7KB |

### 📝 Community (커뮤니티)
| 파일 | 설명 | 크기 |
|------|------|------|
| `posts.json` | 게시글 목록 | 3.2KB |
| `post-detail.json` | 게시글 상세 | 611B |

### 💳 Orders & Payments (주문/결제)
| 파일 | 설명 | 크기 |
|------|------|------|
| `orders.json` | 주문 내역 | 1.8KB |
| `payment-1.json` | 결제 내역 1 | 1.2KB |
| `payment-2.json` | 결제 내역 2 | 1.2KB |

---

## 🚀 사용 방법

### 1. Proxyman Map Local 설정

```
1. Proxyman 실행
2. Tools → Map Local
3. Host: estate.sesac.kr
4. Local Directory: [이 폴더 경로 선택]
5. Rule 활성화
```

### 2. 코드에서 직접 사용

```swift
// AppEnvironment.swift
AppEnvironment.current = .mock

// NetworkManager.swift
if AppEnvironment.current == .mock {
    // 이 폴더의 JSON 파일 로드
    return loadMockData(filename: "hot-estates.json")
}
```

---

## 📊 총 데이터 크기

- **필수 데이터**: 약 1.3MB
- **선택 데이터**: 약 10KB
- **총합**: 약 1.31MB

---

## ✅ 수집 완료 날짜

2026-02-09

---

## 📝 참고

- 원본 파일들은 상위 `proxyman/` 폴더에 보관
- 이 폴더는 깔끔하게 정리된 파일들만 포함
- 파일명은 엔드포인트와 일치하도록 단순화
