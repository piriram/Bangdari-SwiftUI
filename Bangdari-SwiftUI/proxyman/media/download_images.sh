#!/bin/bash
BASE_URL="http://estate.sesac.kr:42449"
TOTAL=$(wc -l < image_urls.txt)
COUNT=0

mkdir -p images/banners images/estates images/chats images/posts

while IFS= read -r path; do
    COUNT=$((COUNT + 1))
    
    # 상대 경로에서 디렉토리 구조 추출
    DIR=$(dirname "$path" | sed 's/^\/data\///')
    FILE=$(basename "$path")
    
    # 출력 경로 결정
    if [[ "$path" == /data/banners/* ]]; then
        OUTPUT="images/banners/$FILE"
    elif [[ "$path" == /data/estates/* ]]; then
        OUTPUT="images/estates/$FILE"
    elif [[ "$path" == /data/chats/* ]]; then
        OUTPUT="images/chats/$FILE"
    elif [[ "$path" == /data/posts/* ]]; then
        OUTPUT="images/posts/$FILE"
    else
        OUTPUT="images/$FILE"
    fi
    
    # 이미 존재하면 스킵
    if [ -f "$OUTPUT" ]; then
        echo "[$COUNT/$TOTAL] 스킵: $FILE"
        continue
    fi
    
    # 다운로드
    URL="${BASE_URL}${path}"
    echo "[$COUNT/$TOTAL] 다운로드: $URL → $OUTPUT"
    curl -s -f "$URL" -o "$OUTPUT" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  ✓ 성공"
    else
        echo "  ✗ 실패"
    fi
    
    # 서버 부담 방지
    sleep 0.1
done < image_urls.txt

echo ""
echo "=== 다운로드 완료 ==="
echo "이미지: $(find images -type f | wc -l)개"
