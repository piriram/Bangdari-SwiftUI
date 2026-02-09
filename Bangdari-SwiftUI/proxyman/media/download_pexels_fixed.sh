#!/bin/bash

# Pexels API 설정
API_KEY="ighxYBvs3uxwspIEedsy392W2T0c6Ihg8xqTqZglwxbE98eU11jVmiFS"
API_URL="https://api.pexels.com/v1"

# 색상 출력
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🖼️  Pexels 이미지 다운로드 시작..."
echo ""

# 현재 파일 개수 확인
CURRENT_ESTATES=$(find images/estates -name "*.jpg" 2>/dev/null | wc -l | xargs)
CURRENT_POSTS=$(find images/posts -name "*.jpg" 2>/dev/null | wc -l | xargs)

echo "현재 상태:"
echo "  매물: ${CURRENT_ESTATES}/40개"
echo "  게시글: ${CURRENT_POSTS}/11개"
echo ""

# 1. 매물 이미지 추가 (apartment interior, 15개)
echo -e "${BLUE}[매물 1/2]${NC} apartment interior 검색..."
RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
    "${API_URL}/search?query=apartment+interior&per_page=15&orientation=landscape")

COUNTER=16
echo "$RESPONSE" | jq -r '.photos[].src.large' | while read -r url; do
    FILENAME="estate_${COUNTER}.jpg"
    OUTPUT="images/estates/${FILENAME}"

    curl -s "$url" -o "$OUTPUT"
    SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
    echo -e "  [${COUNTER}] ${GREEN}✓${NC} $FILENAME ($SIZE)"

    COUNTER=$((COUNTER + 1))
    sleep 0.2
done

# 2. 매물 이미지 추가 (modern bedroom, 10개)
echo ""
echo -e "${BLUE}[매물 2/2]${NC} modern bedroom 검색..."
RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
    "${API_URL}/search?query=modern+bedroom&per_page=10&orientation=landscape")

COUNTER=31
echo "$RESPONSE" | jq -r '.photos[].src.large' | while read -r url; do
    FILENAME="estate_${COUNTER}.jpg"
    OUTPUT="images/estates/${FILENAME}"

    curl -s "$url" -o "$OUTPUT"
    SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
    echo -e "  [${COUNTER}] ${GREEN}✓${NC} $FILENAME ($SIZE)"

    COUNTER=$((COUNTER + 1))
    sleep 0.2
done

# 3. 게시글 이미지 추가 (house architecture, 6개)
echo ""
echo -e "${BLUE}[게시글]${NC} house architecture 검색..."
RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
    "${API_URL}/search?query=house+architecture&per_page=6&orientation=landscape")

COUNTER=6
echo "$RESPONSE" | jq -r '.photos[].src.large' | while read -r url; do
    FILENAME="post_${COUNTER}.jpg"
    OUTPUT="images/posts/${FILENAME}"

    curl -s "$url" -o "$OUTPUT"
    SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
    echo -e "  [${COUNTER}] ${GREEN}✓${NC} $FILENAME ($SIZE)"

    COUNTER=$((COUNTER + 1))
    sleep 0.2
done

echo ""
echo "✅ 다운로드 완료!"
echo ""
echo "=== 최종 결과 ==="
echo "배너: $(find images/banners -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "매물: $(find images/estates -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "채팅: $(find images/chats -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo "게시글: $(find images/posts -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
echo ""
echo "총: $(find images -name "*.jpg" 2>/dev/null | wc -l | xargs)개"
