#!/bin/bash

# Pexels API 설정
API_KEY="ighxYBvs3uxwspIEedsy392W2T0c6Ihg8xqTqZglwxbE98eU11jVmiFS"
API_URL="https://api.pexels.com/v1"

# 색상 출력
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🖼️  Pexels 이미지 다운로드 시작..."
echo ""

# 현재 파일 개수 확인
CURRENT_ESTATES=$(find images/estates -name "*.jpg" 2>/dev/null | wc -l | xargs)
CURRENT_POSTS=$(find images/posts -name "*.jpg" 2>/dev/null | wc -l | xargs)

echo "현재 상태:"
echo "  매물: ${CURRENT_ESTATES}/40개"
echo "  게시글: ${CURRENT_POSTS}/11개"
echo ""

# 카테고리별 다운로드 함수
download_pexels_images() {
    local category=$1
    local query=$2
    local count=$3
    local output_dir=$4
    local start_index=$5

    echo -e "${BLUE}[$category]${NC} $count개 다운로드 중... (검색어: $query)"

    # Pexels API 호출
    RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
        "${API_URL}/search?query=${query}&per_page=${count}&orientation=landscape")

    # 이미지 URL 추출
    URLS=$(echo "$RESPONSE" | jq -r '.photos[].src.large // empty')

    if [ -z "$URLS" ]; then
        echo -e "  ${YELLOW}⚠${NC} API 에러 또는 결과 없음"
        return
    fi

    # 다운로드
    local index=$start_index
    echo "$URLS" | while IFS= read -r url; do
        FILENAME="${category}_${index}.jpg"
        OUTPUT_PATH="${output_dir}/${FILENAME}"

        curl -s "$url" -o "$OUTPUT_PATH"

        if [ $? -eq 0 ]; then
            SIZE=$(ls -lh "$OUTPUT_PATH" 2>/dev/null | awk '{print $5}')
            echo -e "  [${index}] ${GREEN}✓${NC} $FILENAME ($SIZE)"
        else
            echo -e "  [${index}] ✗ 다운로드 실패"
        fi

        index=$((index + 1))
        sleep 0.2
    done

    echo ""
}

# 매물 이미지 추가 (15 → 40개, 25개 더 필요)
echo -e "${YELLOW}매물 이미지 추가 다운로드${NC}"
download_pexels_images "estate" "apartment interior" 15 "images/estates" 16
download_pexels_images "estate" "modern bedroom" 10 "images/estates" 31

# 게시글 이미지 추가 (5 → 11개, 6개 더 필요)
echo -e "${YELLOW}게시글 이미지 추가 다운로드${NC}"
download_pexels_images "post" "house architecture" 6 "images/posts" 6

echo "✅ 다운로드 완료!"
echo ""
echo "=== 최종 결과 ==="
echo "배너: $(find images/banners -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "매물: $(find images/estates -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "채팅: $(find images/chats -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "게시글: $(find images/posts -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo ""
echo "총: $(find images -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
