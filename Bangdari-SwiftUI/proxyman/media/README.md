# 목업 미디어 파일

> 서버 종료 후 포트폴리오 시연용 이미지 & 비디오

## 📊 데이터 현황

### 이미지 (56개, 6.5MB)
- **배너**: 4개 (Unsplash)
- **매물**: 40개 (Unsplash + Pexels)
- **채팅**: 1개 (Unsplash)
- **게시글**: 11개 (Unsplash + Pexels)

### 비디오 (3개, 20MB)
- **부동산 투어**: 3개 (Pexels Videos)
  - video_1.mp4 (6.2MB, 15초)
  - video_2.mp4 (7.7MB, 24초)
  - video_3.mp4 (4.8MB, 25초)

**총 용량**: 26MB

---

## 🎨 이미지 출처

모든 이미지는 상업적 사용이 허용된 무료 이미지입니다:
- **Unsplash**: https://unsplash.com (License: Free to use)
- **Pexels**: https://www.pexels.com (License: Free to use)

---

## 🚀 Proxyman 설정 방법

### 1. Map Local (이미지)

**이미지 URL을 로컬 파일로 매핑:**

```
Proxyman → Tools → Map Local

Rule 1: 배너 이미지
  If: URL matches "*/data/banners/*"
  Then: Map to Local Directory
  Local Path: [이 폴더]/images/banners/
  Matching: Wildcard

Rule 2: 매물 이미지
  If: URL matches "*/data/estates/*"
  Then: Map to Local Directory
  Local Path: [이 폴더]/images/estates/
  Matching: Wildcard

Rule 3: 채팅 이미지
  If: URL matches "*/data/chats/*"
  Then: Map to Local Directory
  Local Path: [이 폴더]/images/chats/
  Matching: Wildcard

Rule 4: 게시글 이미지
  If: URL matches "*/data/posts/*"
  Then: Map to Local Directory
  Local Path: [이 폴더]/images/posts/
  Matching: Wildcard (이미지만)
```

### 2. Map Local (비디오)

**비디오 URL을 로컬 파일로 매핑:**

```
Proxyman → Tools → Map Local

Rule: 비디오 파일
  If: URL matches "*/data/posts/*.mp4"
  Then: Map to Local Directory
  Local Path: [이 폴더]/videos/
  Matching: Wildcard
```

### 3. Map Remote (대안)

특정 URL을 다른 URL로 리다이렉트:

```
원본: http://estate.sesac.kr:42449/data/estates/estate_12_*.jpg
→ 로컬: file://[절대경로]/images/estates/estate_1.jpg
```

---

## 📝 파일 네이밍 규칙

### 이미지
```
images/
  banners/
    banner_1.jpg ~ banner_4.jpg
  estates/
    estate_1.jpg ~ estate_40.jpg
  chats/
    chat_1.jpg
  posts/
    post_1.jpg ~ post_11.jpg
```

### 비디오
```
videos/
  video_1.mp4 ~ video_3.mp4
```

---

## 🔄 재다운로드

스크립트가 포함되어 있습니다:

```bash
# Unsplash 이미지 (API Key 필요)
./download_unsplash.sh

# Pexels 이미지 (API Key 필요)
./download_pexels_fixed.sh

# Pexels 비디오 (API Key 필요)
./download_videos.sh
```

**API Keys:**
- Unsplash: https://unsplash.com/developers
- Pexels: https://www.pexels.com/api/

---

## ✅ 다운로드 완료

- 날짜: 2026-02-09
- 출처: Unsplash + Pexels
- 라이선스: 무료 (상업적 사용 가능)
