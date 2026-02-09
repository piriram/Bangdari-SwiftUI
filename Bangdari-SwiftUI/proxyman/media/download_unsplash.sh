#!/bin/bash

# Unsplash API 설정
ACCESS_KEY="Le29PHcBQBKULLDq6P3L7I4iw_Iu-OOzloBbuVwBldY"
API_URL="https://api.unsplash.com"

# 폴더 생성
mkdir -p images/banners images/estates images/chats images/posts

# 색상 출력
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🖼️  Unsplash 이미지 다운로드 시작..."
echo ""

# 카테고리별 다운로드 함수
download_images() {
    local category=$1
    local query=$2
    local count=$3
    local output_dir=$4

    echo -e "${BLUE}[$category]${NC} $count개 다운로드 중... (검색어: $query)"

    for i in $(seq 1 $count); do
        # 랜덤 이미지 가져오기
        RESPONSE=$(curl -s "${API_URL}/photos/random?query=${query}&orientation=landscape&client_id=${ACCESS_KEY}")

        # 이미지 URL 추출
        IMAGE_URL=$(echo "$RESPONSE" | jq -r '.urls.regular // .urls.full // empty')

        if [ -z "$IMAGE_URL" ]; then
            echo "  [$i/$count] ✗ API 에러 (Rate limit?)"
            sleep 2
            continue
        fi

        # 파일명 생성
        FILENAME="${category}_${i}.jpg"
        OUTPUT_PATH="${output_dir}/${FILENAME}"

        # 다운로드
        curl -s "$IMAGE_URL" -o "$OUTPUT_PATH"

        if [ $? -eq 0 ]; then
            SIZE=$(ls -lh "$OUTPUT_PATH" | awk '{print $5}')
            echo -e "  [$i/$count] ${GREEN}✓${NC} $FILENAME ($SIZE)"
        else
            echo "  [$i/$count] ✗ 다운로드 실패"
        fi

        # API Rate Limit 방지 (50 requests/hour)
        sleep 0.5
    done

    echo ""
}

# 1. 배너 이미지 (4개) - 넓은 풍경
download_images "banner" "modern+house+exterior" 4 "images/banners"

# 2. 매물 이미지 (40개) - 다양한 각도
download_images "estate" "apartment+interior" 15 "images/estates"
download_images "estate" "modern+living+room" 15 "images/estates"
download_images "estate" "house+exterior" 10 "images/estates"

# 3. 채팅 이미지 (1개)
download_images "chat" "house+keys" 1 "images/chats"

# 4. 게시글 이미지 (11개)
download_images "post" "real+estate" 6 "images/posts"
download_images "post" "house+interior" 5 "images/posts"

echo "✅ 다운로드 완료!"
echo ""
echo "=== 결과 ==="
echo "배너: $(ls -1 images/banners/*.jpg 2>/dev/null | wc -l | xargs)개"
echo "매물: $(ls -1 images/estates/*.jpg 2>/dev/null | wc -l | xargs)개"
echo "채팅: $(ls -1 images/chats/*.jpg 2>/dev/null | wc -l | xargs)개"
echo "게시글: $(ls -1 images/posts/*.jpg 2>/dev/null | wc -l | xargs)개"
echo ""
echo "총: $(find images -name "*.jpg" | wc -l | xargs)개"
