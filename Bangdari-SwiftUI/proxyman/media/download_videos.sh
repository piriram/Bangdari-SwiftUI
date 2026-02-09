#!/bin/bash

# Pexels API 설정
API_KEY="ighxYBvs3uxwspIEedsy392W2T0c6Ihg8xqTqZglwxbE98eU11jVmiFS"
API_URL="https://api.pexels.com/videos"

# 색상 출력
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🎥 Pexels 비디오 다운로드 시작..."
echo ""

# 폴더 생성
mkdir -p videos

# 비디오 검색 및 다운로드
echo -e "${BLUE}[비디오]${NC} real estate 검색 (3개)..."

RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
    "${API_URL}/search?query=house+tour&per_page=3&orientation=landscape")

# 비디오 정보 확인
TOTAL=$(echo "$RESPONSE" | jq -r '.total_results // 0')
echo "검색 결과: ${TOTAL}개"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} 검색 결과가 없습니다. 다른 검색어로 시도합니다..."
    RESPONSE=$(curl -s -H "Authorization: ${API_KEY}" \
        "${API_URL}/search?query=apartment&per_page=3")
fi

# 비디오 파일 URL 추출 (HD 품질 선택)
COUNTER=1
echo "$RESPONSE" | jq -c '.videos[]' | while read -r video; do
    # 비디오 제목
    TITLE=$(echo "$video" | jq -r '.user.name // "Unknown"')

    # HD 비디오 URL 추출 (width=1280 또는 가장 큰 파일)
    VIDEO_URL=$(echo "$video" | jq -r '
        .video_files[] |
        select(.quality == "hd" or .width == 1280) |
        .link' | head -1)

    # URL이 없으면 첫 번째 파일 선택
    if [ -z "$VIDEO_URL" ]; then
        VIDEO_URL=$(echo "$video" | jq -r '.video_files[0].link')
    fi

    FILENAME="video_${COUNTER}.mp4"
    OUTPUT="videos/${FILENAME}"

    echo -e "  [${COUNTER}/3] 다운로드 중... (by ${TITLE})"

    # 진행률 표시하며 다운로드
    curl -# "$VIDEO_URL" -o "$OUTPUT"

    if [ $? -eq 0 ]; then
        SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
        DURATION=$(echo "$video" | jq -r '.duration // "?"')
        echo -e "  [${COUNTER}/3] ${GREEN}✓${NC} $FILENAME ($SIZE, ${DURATION}초)"
    else
        echo -e "  [${COUNTER}/3] ✗ 다운로드 실패"
    fi

    echo ""
    COUNTER=$((COUNTER + 1))
    sleep 1
done

echo ""
echo "✅ 비디오 다운로드 완료!"
echo ""
echo "=== 최종 결과 ==="
VIDEO_COUNT=$(find videos -name "*.mp4" 2>/dev/null | wc -l | xargs)
echo "비디오: ${VIDEO_COUNT}개"

if [ "$VIDEO_COUNT" -gt 0 ]; then
    TOTAL_SIZE=$(du -sh videos 2>/dev/null | awk '{print $1}')
    echo "총 용량: ${TOTAL_SIZE}"
    echo ""
    echo "파일 목록:"
    ls -lh videos/*.mp4 2>/dev/null | awk '{print "  - " $9 " (" $5 ")"}'
fi
